FROM golang:1.21-bullseye

# Add HashiCorp's GPG key and repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bullseye main" | tee /etc/apt/sources.list.d/hashicorp.list

# Add Kubernetes GPG key and repository
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Install system packages
RUN apt-get update && apt-get install -y \
    git \
    make \
    unzip \
    python3-pip \
    terraform \
    kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages from PyPI
RUN pip3 install --no-cache-dir \
    pre-commit \
    checkov \
    yq

# Install Go packages using go install
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.55.2 && \
    go install github.com/terraform-docs/terraform-docs@v0.16.0 && \
    go install github.com/terraform-linters/tflint@v0.50.0

WORKDIR /workspace

# Pre-install pre-commit hooks in the container
COPY .pre-commit-config.yaml /workspace/
RUN git init && pre-commit install
