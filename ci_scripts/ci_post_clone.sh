#!/bin/zsh

set -e

script_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$script_dir/.."
root_dir=$(pwd)

# Generate file with secrets
if [ -z "$BACKEND_BASE_URL" ]; then
  echo "ERROR: BACKEND_BASE_URL environment variable is not set"
  exit 1
fi

if [ -z "$SERP_API_KEY" ]; then
  echo "ERROR: SERP_API_KEY environment variable is not set"
  exit 1
fi

SECRETS_FILE="${root_dir}/App/Sources/Secrets.swift"

BACKEND_BASE_URL="${BACKEND_BASE_URL}"
SERP_API_KEY="${SERP_API_KEY}"

echo "public struct Secrets {" >> ${SECRETS_FILE}
echo "public static let backendBaseURL = \"${BACKEND_BASE_URL}\"" >> ${SECRETS_FILE}
echo "public static let serpApiKey = \"${SERP_API_KEY}\"" >> ${SECRETS_FILE}
echo "}" >> ${SECRETS_FILE}

# Tuist configuration
export PATH=$PATH":$root_dir/.tuist-bin"

defaults write com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile -bool NO
defaults write com.apple.dt.Xcode IDEDisableAutomaticPackageResolution -bool NO

make
