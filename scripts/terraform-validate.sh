#!/bin/bash
set -euo pipefail

# Find all directories containing .tf files, excluding .terraform directories
tf_dirs=$(find . -type f -name "*.tf" -not -path "*/.terraform/*" -exec dirname {} \; | sort -u)

for dir in $tf_dirs; do
    echo "Validating Terraform in $dir"
    
    # Change to directory
    cd "$dir"
    
    # Remove .terraform directory if it exists
    if [ -d .terraform ]; then
        rm -rf .terraform
    fi
    
    # Initialize Terraform with no backend and download modules
    echo "Initializing Terraform in $dir"
    terraform init -backend=false -get=true
    
    # Validate
    terraform validate
    
    # Return to original directory
    cd - > /dev/null
done
