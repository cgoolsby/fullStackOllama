#!/bin/bash

# Check if a branch name was provided
if [ -z "$1" ]; then
    echo "Error: Please provide a branch name"
    echo "Usage: $0 <branch-name>"
    exit 1
fi

BRANCH_NAME="$1"

# Update the Flux source to point to the specified branch
echo "Updating Flux source to branch: $BRANCH_NAME"
flux reconcile source git flux-system --branch="$BRANCH_NAME"

# Trigger a reconciliation of all Flux resources
echo "Triggering Flux reconciliation..."
flux reconcile kustomization flux-system

echo "Done! Flux is now pointing to branch: $BRANCH_NAME"
