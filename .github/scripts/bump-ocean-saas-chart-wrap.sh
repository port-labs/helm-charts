#!/usr/bin/env bash
# Bump ocean-saas-chart-wrap in an infra-apps checkout to a released port-ocean version.
# Usage: bump-ocean-saas-chart-wrap.sh <infra-apps-root> <port-ocean-version>
set -euo pipefail

INFRA_APPS_ROOT="${1:?infra-apps root is required}"
export PORT_OCEAN_VERSION="${2:?port-ocean version is required}"
CHART_DIR="${INFRA_APPS_ROOT}/internal-charts/ocean-saas-chart-wrap"
CHART_FILE="${CHART_DIR}/Chart.yaml"
HELM_REPO_NAME="port-labs"
HELM_REPO_URL="https://port-labs.github.io/helm-charts/"
MAX_ATTEMPTS="${HELM_REPO_WAIT_ATTEMPTS:-24}"
SLEEP_SECONDS="${HELM_REPO_WAIT_SECONDS:-15}"

if [[ ! -f "${CHART_FILE}" ]]; then
  echo "::error::Chart.yaml not found at ${CHART_FILE}"
  exit 1
fi

current_version="$(yq '.dependencies[] | select(.name == "port-ocean") | .version' "${CHART_FILE}")"

if [[ -z "${current_version}" ]]; then
  echo "::error::Could not read port-ocean dependency version from ${CHART_FILE}"
  exit 1
fi

echo "Current ocean-saas-chart-wrap port-ocean dependency: ${current_version}"
echo "Target port-ocean version: ${PORT_OCEAN_VERSION}"

if [[ "${PORT_OCEAN_VERSION}" == *rc* ]]; then
  echo "Skipping RC version ${PORT_OCEAN_VERSION}."
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

if [[ "${current_version}" == "${PORT_OCEAN_VERSION}" ]]; then
  echo "Already at ${PORT_OCEAN_VERSION}; nothing to do."
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

if [[ "$(printf '%s\n%s\n' "${current_version}" "${PORT_OCEAN_VERSION}" | sort -V | tail -1)" == "${current_version}" ]]; then
  echo "Wrap chart is already ahead (${current_version} > ${PORT_OCEAN_VERSION}); skipping."
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

# Patch-bump the wrap chart's own version (0.1.12 -> 0.1.13). infra-apps
# requires this so the wrapper is treated as a new chart release, matching
# the manual bump PRs.
yq -i '.version |= (split(".") | .[-1] |= ((. | tonumber) + 1 | tostring) | join("."))' "${CHART_FILE}"
# Pin the port-ocean subchart to the version that was just released.
yq -i '(.dependencies[] | select(.name == "port-ocean")).version = strenv(PORT_OCEAN_VERSION)' "${CHART_FILE}"

echo "Updated ${CHART_FILE}:"
grep -n -E '^(version:|  - name: port-ocean|    version:)' "${CHART_FILE}" || true

# Chart.lock digest comes from the published chart, not Chart.yaml. The helm
# repo is GitHub Pages, which can lag the GitHub Release by a minute or two,
# so wait until this exact version is queryable before locking.
helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}" --force-update

found=false
for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  helm repo update "${HELM_REPO_NAME}"
  # helm search prints a header row; awk drops it and grep requires an exact
  # version match so 0.23.3 does not succeed when we asked for 0.23.30.
  if helm search repo "${HELM_REPO_NAME}/port-ocean" --version "${PORT_OCEAN_VERSION}" --versions |
    awk 'NR > 1 { print $2 }' |
    grep -Fxq "${PORT_OCEAN_VERSION}"; then
    found=true
    break
  fi
  echo "Waiting for port-ocean ${PORT_OCEAN_VERSION} in ${HELM_REPO_URL} (attempt ${attempt}/${MAX_ATTEMPTS})"
  sleep "${SLEEP_SECONDS}"
done

if [[ "${found}" != true ]]; then
  echo "::error::port-ocean ${PORT_OCEAN_VERSION} did not appear in ${HELM_REPO_URL}"
  exit 1
fi

# Refresh Chart.lock (digest + generated timestamp) from the live repo.
helm dependency update "${CHART_DIR}"
# helm dependency update also downloads charts/port-ocean-*.tgz. That tarball
# is not part of the wrap-chart contract and must not land in the PR.
rm -f "${CHART_DIR}/charts/"port-ocean-*.tgz

# Tell the workflow a PR is needed. GITHUB_OUTPUT is unset when this script
# is run locally, so fall back to /dev/null.
echo "changed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "Bumped ocean-saas-chart-wrap to port-ocean ${PORT_OCEAN_VERSION}"
