#!/bin/bash
set -euo pipefail

# Default values
GITHUB_OWNER="cgoolsby"
REPO_NAME="fullStackOllama"
BRANCH="main"
FLUX_PATH="infra/base"
GITHUB_TOKEN=${GITHUB_TOKEN:-""}

# Help message
usage() {
    echo "Usage: $0 [-t github_token] [-o github_owner] [-r repo_name] [-b branch] [-p flux_path]"
    echo
    echo "Bootstrap Flux on a Kubernetes cluster"
    echo
    echo "Options:"
    echo "  -t    GitHub personal access token (required if GITHUB_TOKEN env var is not set)"
    echo "  -o    GitHub owner/organization (default: $GITHUB_OWNER)"
    echo "  -r    Repository name (default: $REPO_NAME)"
    echo "  -b    Branch name (default: $BRANCH)"
    echo "  -p    Path in repository for Flux manifests (default: $FLUX_PATH)"
    echo "  -h    Show this help message"
    exit 1
}

# Parse command line arguments
while getopts "t:o:r:b:p:h" opt; do
    case $opt in
        t) GITHUB_TOKEN="$OPTARG" ;;
        o) GITHUB_OWNER="$OPTARG" ;;
        r) REPO_NAME="$OPTARG" ;;
        b) BRANCH="$OPTARG" ;;
        p) FLUX_PATH="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub token is required. Either set GITHUB_TOKEN environment variable or use -t flag."
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "Error: kubectl is not configured or cluster is not accessible"
    exit 1
fi

echo "🔄 Checking Flux CLI installation..."
if ! command -v flux &>/dev/null; then
    echo "⚠️  Flux CLI not found. Installing..."
    brew install fluxcd/tap/flux
fi

echo "🧹 Cleaning up any existing Flux installation..."
flux uninstall --silent || true

echo "🚀 Bootstrapping Flux..."
flux bootstrap github \
    --owner="$GITHUB_OWNER" \
    --repository="$REPO_NAME" \
    --branch="$BRANCH" \
    --path="$FLUX_PATH" \
    --personal \
    --token-auth \
    --components-extra=image-reflector-controller,image-automation-controller

echo "⏳ Waiting for Flux controllers to be ready..."
kubectl -n flux-system wait --for=condition=ready pod --all --timeout=2m

echo "✅ Flux bootstrap completed successfully!"
echo "📊 Checking Flux system health..."
flux check

echo "🔍 Current Flux resources:"
flux get all -A
