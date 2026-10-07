# Session 16: CI/CD with GitHub Actions: Demo Project

**Repository (with the live pipeline):** https://github.com/Aryan-Bhendarkar/session16-cicd-github-actions
**Docker image (published by the pipeline):** `ghcr.io/aryan-bhendarkar/session16-cicd-github-actions:latest`

The project is based on the teacher's `10-final-cicd-pipeline` (app, tests, `build.sh`, CI workflow). I added the two missing deliverables: a **Dockerfile** and a **CD job** that publishes the image.

GitHub Actions only runs workflows from `.github/workflows/` at the **root of a repository**, so the project lives in its own repo instead of a subfolder of the course repo.

---

## 1. CI vs CD

| | CI: Continuous Integration | CD: Continuous Delivery / Deployment |
| :--- | :--- | :--- |
| Question | "Does the new code work?" | "Can we ship it?" |
| Does | Builds and tests every push automatically | Packages the tested build and delivers it (here: a Docker image in a registry) |
| In this project | `test`, `security-check`, `build` jobs | `deliver` job |

## 2. The pipeline

```text
git push to main
      │
      ▼
   [ test ]  checkout → setup Python → install → pytest
      │
      ├────────────────────────┐
      ▼                        ▼
 [ build ]               [ security-check ]
 build.sh → upload       look for .env / *.pem / *.key
 artifact                      │
      └──────────┬─────────────┘
                 ▼
     [ deliver ]  (CD, only on push to main)
     login to ghcr.io → build Docker image → push → smoke test (docker run)
```

`needs:` makes jobs wait for earlier ones, so if tests fail, nothing after them runs.

## 3. GitHub Actions concepts (as used in `.github/workflows/ci.yml`)

| Concept | Where it appears |
| :--- | :--- |
| **Workflow** | `ci.yml`: the whole automated process. Triggers: `push` to `main`, `pull_request`, `workflow_dispatch` (manual) |
| **Jobs** | `test`, `build`, `security-check`, `deliver`. Jobs run in parallel unless `needs:` orders them |
| **Steps** | The items inside a job, either `uses:` (a ready-made action such as `actions/checkout`) or `run:` (a shell command such as `pytest -v`) |
| **Runners** | `runs-on: ubuntu-latest`: a fresh GitHub-hosted Linux VM for every job, thrown away afterwards |
| **Secrets** | `${{ secrets.GITHUB_TOKEN }}`: a secret GitHub creates automatically for each run. The `deliver` job uses it to log in to `ghcr.io`, so no password is stored in the code. Own secrets can be added under Settings → Secrets and variables → Actions |
| **Artifacts** | `actions/upload-artifact` stores the `build/` folder as `calculator-build` so it can be downloaded after the run |
| **Build** | `build.sh` copies the app into `build/` and writes `build-info.txt`. The Dockerfile builds the container image |
| **Test** | `pytest -v` runs `tests/test_calculator.py` (add, subtract, multiply, divide, divide-by-zero) |

## 4. Project contents

```text
session16-cicd-github-actions/
├── .github/workflows/ci.yml   CI + CD workflow
├── app/calculator.py          application source code
├── tests/test_calculator.py   unit tests
├── build.sh                   build script
├── Dockerfile                 container image (python:3.12-slim + the app)
├── requirements.txt           pytest
├── .gitattributes             keeps *.sh files in Unix (LF) line endings
└── .gitignore
```

`Dockerfile` (added by me):
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app/ ./app/
CMD ["python", "-c", "from app.calculator import add, subtract, multiply, divide; print('10 + 5 =', add(10, 5)); ..."]
```
CD job (added by me, at the end of `ci.yml`): `needs: [build, security-check]`, runs only when `github.event_name == 'push' && github.ref == 'refs/heads/main'`, with `permissions: packages: write`. It uses `docker/login-action`, `docker/metadata-action` (generates the lowercase image name and the `latest` and `sha-<commit>` tags), `docker/build-push-action`, then runs the pushed image as a smoke test.

I also built and ran the Dockerfile locally before pushing: it printed `10 + 5 = 15`, `10 - 5 = 5`, `10 * 5 = 50`, `10 / 5 = 2.0`.

---

## 5. Successful pipeline execution

**Run #2 ("Fix build.sh line endings", commit `e43d8e7`): all jobs green, 53 s.** Test → (Build + Security Check) → CD.

![pipeline](images/cicd-1-pipeline.png)

**Artifacts produced by the run:** `calculator-build` (the build output, 902 bytes) and a `.dockerbuild` record automatically created by the Docker build step.

![artifacts](images/cicd-2-artifact.png)

**Test job:** every step passed, including "Install dependencies" and "Run tests".

![tests](images/cicd-3-test.png)

**CD result:** the pipeline published the image to GitHub Container Registry with tags `latest` and `sha-e43d8e7`. Anyone can pull it with `docker pull ghcr.io/aryan-bhendarkar/session16-cicd-github-actions:sha-e43d8e7`.

![package](images/cicd-4-package.png)

---

## 6. Troubleshooting: the first run failed

**What I saw:** the first run (commit `b52b94a`, "Add CI/CD pipeline with Docker delivery") showed **Test ✓, Security Check ✓, Build ✗**, and the CD job was skipped. That is the `needs` chain working: because Build failed, nothing after it ran.

**Investigation:** the Build job's log showed:
```text
./build.sh: cannot execute: required file not found
Error: Process completed with exit code 127.
```
Exit code 127 means "command not found". Tests passed, so the app was fine, and the problem was specific to running `build.sh`.

**Root cause:** `build.sh` had **Windows (CRLF) line endings**. Its first line was `#!/bin/bash\r`, and the Linux runner looked for an interpreter literally named `bash\r`, which doesn't exist. I confirmed it locally with `file build.sh` ("with CRLF line terminators").

**Fix:** converted the file to Unix line endings (`sed -i 's/\r$//' build.sh`) and added a `.gitattributes` file with `*.sh text eol=lf`, so git always stores shell scripts with Unix line endings. I committed it as "Fix build.sh line endings" and pushed.

**Verify:** the new push triggered run #2, and all four jobs passed (section 5). Using "Re-run jobs" on the old run would not have helped, because a re-run repeats the same commit; the fix needed a new commit.

## 7. Failure scenario: why `needs` matters

If a test fails (for example, changing `add` to return `a + b + 1`), the `test` job goes red and `build`, `security-check` and `deliver` are skipped, so a broken version is never packaged or published. I did not run this scenario separately; the first-run failure above demonstrated the same behaviour for the `build` → `deliver` link.

## 8. Run it locally

```bash
python3 -m pip install -r requirements.txt
pytest -v                       # tests
chmod +x build.sh && ./build.sh # build
docker build -t calculator .    # container image
docker run --rm calculator
```

## 9. What I learned

- CI checks every change automatically, and CD turns the passing result into something deployable.
- A workflow is made of jobs, jobs are made of steps, and every job runs on a fresh runner.
- `needs` creates the pipeline order and stops later stages when an earlier one fails.
- Secrets such as `GITHUB_TOKEN` keep credentials out of the code.
- Artifacts keep the build output after the runner is gone.
- Windows line endings can break shell scripts on Linux runners: read the log, find the exact error, and fix the root cause.
