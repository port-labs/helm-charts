#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine the base branch - use GITHUB_BASE_REF for PRs, otherwise use main
BASE_BRANCH="${GITHUB_BASE_REF:-main}"
echo "Checking for chart changes against base branch: origin/${BASE_BRANCH}"

# Get list of changed files
CHANGED_FILES=$(git diff --name-only origin/${BASE_BRANCH}...HEAD)

if [ -z "$CHANGED_FILES" ]; then
  echo -e "${GREEN}✓ No changes detected${NC}"
  exit 0
fi

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Track if we found any violations
VIOLATIONS_FOUND=0

# Get list of all chart directories
CHART_DIRS=$(find charts -mindepth 1 -maxdepth 1 -type d)

for CHART_DIR in $CHART_DIRS; do
  CHART_NAME=$(basename "$CHART_DIR")
  CHART_YAML="${CHART_DIR}/Chart.yaml"

  if [ ! -f "$CHART_YAML" ]; then
    echo -e "${YELLOW}⚠ Skipping ${CHART_DIR} - no Chart.yaml found${NC}"
    continue
  fi

  # Check if any files in this chart directory changed (excluding Chart.yaml and Chart.lock)
  CONTENT_CHANGES=$(echo "$CHANGED_FILES" | grep "^${CHART_DIR}/" | grep -v "Chart.yaml$" | grep -v "Chart.lock$" || true)

  if [ -z "$CONTENT_CHANGES" ]; then
    echo -e "${GREEN}✓ ${CHART_NAME}: No content changes${NC}"
    continue
  fi

  # Content was changed, now check if version was bumped
  echo -e "\n${YELLOW}Checking ${CHART_NAME} - content files changed:${NC}"
  echo "$CONTENT_CHANGES" | sed 's/^/  /'

  # Get current version
  CURRENT_VERSION=$(grep "^version:" "$CHART_YAML" | awk '{print $2}')

  # Get previous version from base branch
  PREVIOUS_VERSION=$(git show origin/${BASE_BRANCH}:${CHART_YAML} 2>/dev/null | grep "^version:" | awk '{print $2}' || echo "")

  if [ -z "$PREVIOUS_VERSION" ]; then
    echo -e "${GREEN}✓ ${CHART_NAME}: New chart (version: ${CURRENT_VERSION})${NC}"
    continue
  fi

  echo "  Current version:  ${CURRENT_VERSION}"
  echo "  Previous version: ${PREVIOUS_VERSION}"

  if [ "$CURRENT_VERSION" = "$PREVIOUS_VERSION" ]; then
    echo -e "${RED}✗ ${CHART_NAME}: Chart content changed but version was not bumped!${NC}"
    echo -e "${RED}  Please update the version in ${CHART_YAML}${NC}"
    VIOLATIONS_FOUND=1
  else
    echo -e "${GREEN}✓ ${CHART_NAME}: Version bumped from ${PREVIOUS_VERSION} to ${CURRENT_VERSION}${NC}"
  fi
done

echo ""
if [ $VIOLATIONS_FOUND -eq 1 ]; then
  echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}ERROR: Chart changes detected without version bumps!${NC}"
  echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Action required:${NC}"
  echo -e "  1. Update the 'version' field in Chart.yaml for any modified charts"
  echo -e "  2. Follow semantic versioning (https://semver.org/):"
  echo -e "     - MAJOR version for incompatible API changes"
  echo -e "     - MINOR version for backwards-compatible functionality"
  echo -e "     - PATCH version for backwards-compatible bug fixes"
  exit 1
else
  echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✓ All chart version checks passed!${NC}"
  echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
  exit 0
fi
