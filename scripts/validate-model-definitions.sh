#!/bin/bash
set -euo pipefail

# Validate Ollama model definitions
for file in "$@"; do
    echo "Validating model definition: $file"
    
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

    # Validate required fields
    if ! yq eval '.spec.from' "$file" > /dev/null; then
        echo "Error: Missing required field 'spec.from' in $file"
        exit 1
    fi

    if ! yq eval '.spec.build' "$file" > /dev/null; then
        echo "Error: Missing required field 'spec.build' in $file"
        exit 1
    fi

    # Validate model definition structure
    if ! kubectl create -f "$file" --dry-run=client; then
        echo "Error: Invalid model definition structure in $file"
        exit 1
    fi

    echo "✅ $file is valid"
done
