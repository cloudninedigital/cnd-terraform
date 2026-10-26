"""Run a Dataform repository's tags once, with compilation variables from the environment.

Standard library only, so it runs on a stock Python image: the
dataform_cloud_run_job module passes this file to `python3 -c`, and there is no
image to build. Configuration (all environment variables):

  DATAFORM_PROJECT, DATAFORM_REGION, DATAFORM_REPOSITORY   where the repository lives
  DATAFORM_GIT_COMMITISH        branch / tag / commit to compile (default: main)
  DATAFORM_TAGS                 comma-separated tags to run (empty: the whole graph)
  DATAFORM_VARS                 JSON object of fixed compilation vars
  DATAFORM_VARS_FROM_ENV        JSON object {dataform_var: ENV_NAME}; each var is
                                read from that environment variable at run time,
                                e.g. {"client_id": "CLIENT_ID"} with CLIENT_ID set
                                by a workflow execution. Unset or empty: the
                                repository's own default is kept.
  DATAFORM_CODE_COMPILATION_CONFIG  JSON merged into codeCompilationConfig
                                (schemaSuffix, tablePrefix, defaultDatabase, ...)
  DATAFORM_INCLUDE_DEPENDENCIES / DATAFORM_INCLUDE_DEPENDENTS / DATAFORM_FULL_REFRESH
                                "true" / "false"
  DATAFORM_SERVICE_ACCOUNT      service account the invocation runs as (optional)
  DATAFORM_POLL_SECONDS         status poll interval (default 15)

Authentication: the metadata server on Cloud Run; locally GOOGLE_OAUTH_ACCESS_TOKEN
or `gcloud auth print-access-token`. Exits non-zero when compilation or any
action fails, so the Cloud Run job (and a workflow waiting on it) fails too.
"""

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://dataform.googleapis.com/v1"
METADATA_TOKEN = (
    "http://metadata.google.internal/computeMetadata/v1/"
    "instance/service-accounts/default/token"
)
TERMINAL = {"SUCCEEDED", "FAILED", "CANCELLED"}


def log(message, **fields):
    # One JSON line per event: Cloud Logging parses it into a structured entry.
    print(json.dumps({"message": message, **fields}), flush=True)


def flag(name, default=False):
    return os.environ.get(name, str(default)).strip().lower() in ("1", "true", "yes")


def json_env(name):
    raw = os.environ.get(name, "").strip()
    if not raw:
        return {}
    value = json.loads(raw)
    if not isinstance(value, dict):
        raise SystemExit(f"{name} must be a JSON object")
    return value


def access_token():
    if os.environ.get("GOOGLE_OAUTH_ACCESS_TOKEN"):
        return os.environ["GOOGLE_OAUTH_ACCESS_TOKEN"]
    try:
        request = urllib.request.Request(METADATA_TOKEN, headers={"Metadata-Flavor": "Google"})
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.load(response)["access_token"]
    except OSError:
        # Not on Google Cloud: use the local gcloud login.
        return subprocess.check_output(
            ["gcloud", "auth", "print-access-token"], text=True
        ).strip()


def call(method, url, body=None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    request = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Bearer {access_token()}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise SystemExit(f"{method} {url} failed: HTTP {exc.code} {exc.read().decode()[:2000]}")


def compilation_vars():
    variables = {k: str(v) for k, v in json_env("DATAFORM_VARS").items()}
    for var, env_name in json_env("DATAFORM_VARS_FROM_ENV").items():
        value = os.environ.get(env_name, "").strip()
        if value:
            variables[var] = value
        else:
            log("runtime var not set, repository default kept", var=var, env=env_name)
    return variables


def main():
    repository = (
        f"projects/{os.environ['DATAFORM_PROJECT']}/locations/{os.environ['DATAFORM_REGION']}"
        f"/repositories/{os.environ['DATAFORM_REPOSITORY']}"
    )
    tags = [t.strip() for t in os.environ.get("DATAFORM_TAGS", "").split(",") if t.strip()]
    config = {**json_env("DATAFORM_CODE_COMPILATION_CONFIG"), "vars": compilation_vars()}

    compilation = call("POST", f"{API}/{repository}/compilationResults", {
        "gitCommitish": os.environ.get("DATAFORM_GIT_COMMITISH", "main"),
        "codeCompilationConfig": config,
    })
    errors = compilation.get("compilationErrors") or []
    log("compiled", compilation=compilation.get("name"), vars=config["vars"], errors=len(errors))
    if errors:
        for error in errors:
            log("compilation error", path=error.get("path"), error=error.get("message"))
        raise SystemExit(1)

    invocation_config = {
        "includedTags": tags,
        "transitiveDependenciesIncluded": flag("DATAFORM_INCLUDE_DEPENDENCIES", True),
        "transitiveDependentsIncluded": flag("DATAFORM_INCLUDE_DEPENDENTS"),
        "fullyRefreshIncrementalTablesEnabled": flag("DATAFORM_FULL_REFRESH"),
    }
    if os.environ.get("DATAFORM_SERVICE_ACCOUNT"):
        invocation_config["serviceAccount"] = os.environ["DATAFORM_SERVICE_ACCOUNT"]
    invocation = call("POST", f"{API}/{repository}/workflowInvocations", {
        "compilationResult": compilation["name"],
        "invocationConfig": invocation_config,
    })
    name = invocation["name"]
    log("invocation started", invocation=name, tags=tags)

    poll = float(os.environ.get("DATAFORM_POLL_SECONDS", "15"))
    state = invocation.get("state", "RUNNING")
    while state not in TERMINAL:
        time.sleep(poll)
        state = call("GET", f"{API}/{name}").get("state", "RUNNING")

    actions = call("GET", f"{API}/{name}:query").get("workflowInvocationActions", [])
    for action in actions:
        if action.get("state") not in ("SUCCEEDED", "SKIPPED"):
            target = action.get("target") or {}
            log("action " + str(action.get("state")).lower(),
                target=f"{target.get('schema')}.{target.get('name')}",
                reason=action.get("failureReason"))
    log("invocation finished", invocation=name, state=state, actions=len(actions))
    if state != "SUCCEEDED":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
