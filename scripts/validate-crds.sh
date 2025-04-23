#!/bin/bash
set -euo pipefail

# Validate CRD syntax and structure
for file in "$@"; do
    echo "Validating CRD: $file"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        exit 1
    fi

    # Validate YAML syntax
    if ! yq eval '.' "$file" > /dev/null; then
        echo "Error: Invalid YAML in $file"
        exit 1
    fi

    # Validate CRD structure
    if ! kubectl create -f "$file" --dry-run=client; then
        echo "Error: Invalid CRD structure in $file"
        exit 1
    fi

    # Additional CRD-specific validations can be added here
    echo "✅ $file is valid"
done
