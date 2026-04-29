#!/bin/bash
set -euo pipefail

cd "/app/pydantic-assessment"

cat > /tmp/solution.patch <<'__SOLUTION__'
<PASTE YOUR UNIFIED DIFF HERE>
__SOLUTION__

git apply --verbose /tmp/solution.patch
