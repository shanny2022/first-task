#!/bin/bash
set -uo pipefail

cleanup_and_reward() {
    local exit_code=$?
    mkdir -p /logs/verifier
    [ "${exit_code}" -eq 0 ] && echo 1 > /logs/verifier/reward.txt || echo 0 > /logs/verifier/reward.txt
    rm -f "$STDOUT_LOG" "$STDERR_LOG" 2>/dev/null || true
    exit "${exit_code}"
}
STDOUT_LOG=$(mktemp)
STDERR_LOG=$(mktemp)
export STDOUT_LOG STDERR_LOG
trap cleanup_and_reward EXIT

cd "/app/pydantic-assessment" 2>/dev/null || { echo "ERROR: /app/pydantic-assessment missing"; exit 1; }

# Apply test_patch from config.json if present (creates test files at base commit)
python3 -c "
import json, subprocess, sys, tempfile
with open('/tests/config.json') as f:
    cfg = json.load(f)
patch = cfg.get('test_patch', '')
if patch:
    with tempfile.NamedTemporaryFile(mode='w', suffix='.patch', delete=False) as pf:
        pf.write(patch)
        pf.flush()
        r = subprocess.run(['git', 'apply', '--verbose', pf.name], capture_output=True, text=True)
        if r.returncode != 0:
            print(f'WARNING: test_patch apply failed: {r.stderr}', file=sys.stderr)
        else:
            print('Applied test_patch successfully')
" 2>&1 || true

TEST_FILES=$(python3 -c "
import json
with open('/tests/config.json') as f:
    cfg = json.load(f)
tf = cfg.get('selected_test_files_to_run') or []
if isinstance(tf, str):
    import json as _j
    tf = _j.loads(tf)
print(','.join(tf))
" 2>/dev/null || echo "")

set +e
if [ -n "$TEST_FILES" ]; then
    bash /tests/run_script.sh "$TEST_FILES" > "$STDOUT_LOG" 2> "$STDERR_LOG"
else
    bash /tests/run_script.sh > "$STDOUT_LOG" 2> "$STDERR_LOG"
fi
set -e

python3 /tests/parser.py "$STDOUT_LOG" "$STDERR_LOG" /tmp/output.json

if [ ! -f /tmp/output.json ]; then
    echo "ERROR: Parser did not generate output.json"
    echo "=== STDOUT ==="; cat "$STDOUT_LOG"
    echo "=== STDERR ==="; cat "$STDERR_LOG"
    exit 1
fi

mkdir -p /logs/verifier
cp /tmp/output.json /logs/verifier/output.json 2>/dev/null || true
cp "$STDOUT_LOG" /logs/verifier/run-script-stdout.txt 2>/dev/null || true
cp "$STDERR_LOG" /logs/verifier/run-script-stderr.txt 2>/dev/null || true

python3 << 'PYEOF'
import json, sys

with open('/tmp/output.json') as f:
    results = json.load(f)
with open('/tests/config.json') as f:
    cfg = json.load(f)

def parse_tests(x):
    if isinstance(x, str):
        try: return json.loads(x)
        except: return []
    return x or []

ftp = set(parse_tests(cfg.get('fail_to_pass')))
ptp = set(parse_tests(cfg.get('pass_to_pass')))
passed = {t['name'] for t in results.get('tests', []) if t.get('status') == 'PASSED'}

required = ftp | ptp
ok = required <= passed

print(f"required tests : {len(required)}")
print(f"passed tests   : {len(passed)}")
print(f"required passed: {len(required & passed)}")
if ok:
    print("\nRESULT: PASSED")
    sys.exit(0)
missing = required - passed
print(f"\nRESULT: FAILED\nmissing: {sorted(missing)}")
sys.exit(1)
PYEOF
exit $?
