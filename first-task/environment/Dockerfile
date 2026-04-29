FROM us-docker.pkg.dev/afterqueryai/silver-repo-images/pydantic-assessment-tokwn@sha256:69afc7d61716218b4843148af521659861cdf0fef386fc5592daee2bb6c514f2

ENTRYPOINT []

WORKDIR "/app/pydantic-assessment"

RUN set -e \
 && git reset --hard 9e9a11132c980c4ec84ff6d2df06d4c1a55ca8f3 \
 && git clean -fd \
 && git checkout 9e9a11132c980c4ec84ff6d2df06d4c1a55ca8f3

RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || true

RUN pip install --no-cache-dir pytest jsonschema

RUN mkdir -p /logs/verifier
