# Full Stack AI Engineering Platform

This repository is a showcase and evolving codebase for building and orchestrating AI systems from the ground up—designed by a Full Stack AI Engineer with end-to-end expertise across mathematics, data engineering, software development, and Kubernetes-based infrastructure.

## 🎯 Purpose

This project demonstrates a complete, production-grade architecture to:
- Operate an **LLM cluster** using [Ollama](https://ollama.com/) models.
- Harness GPU acceleration using the **NVIDIA GPU Operator** on Kubernetes.
- Use **Custom Resource Definitions (CRDs)** and controllers to coordinate model behaviors.
- Create an ecosystem where multiple models can collaborate to perform higher-level tasks (question answering, summarization, classification, etc.).
- Establish infrastructure-as-code patterns using **Kustomize**, **Flux**, and GitOps principles.

## 🧠 Vision

AI systems are rarely “one model fits all.” This project introduces a framework where **specialized AI agents (LLMs)**, hosted as services across a Kubernetes cluster, can **interoperate** to complete sophisticated tasks.

Inspired by:
- *Full-stack software engineering* principles
- *Multi-agent systems*
- *MLOps best practices*
- *Declarative infrastructure management*

---

## 🔧 Architecture Overview

### 📁 Repository Structure

```bash
.
├── infra/
│   ├── cluster-iac/            # Infrastructure as Code (Terraform) for deploying an EKS cluster with requisite GPU support
│   ├── base/                    # Base Kustomize configurations (Flux, GPU Operator, etc.)
│   ├── overlays/                # Cluster-specific configurations
│   ├── flux/                    # Flux GitOps setup
│   └── monitoring/              # Prometheus/Grafana, if used
│
├── crds/                        # Custom Resource Definitions (YAML) and Go types
│   ├── ollamaagent_crd.yaml    # Defines OllamaAgent behavior/contract
│   ├── ollamamodeldefinition_crd.yaml
│   └── taskorchestration_crd.yaml
│
├── controllers/                 # Golang operators/controllers (kubebuilder-based)
│   ├── ollamaagent_controller.go
│   ├── ollamamodeldefinition_controller.go
│   └── taskorchestration_controller.go
│
├── ollama-operators/            # Model server orchestration logic
│   ├── agent-specialization/   # Specialized agent roles (Q&A, summarizer, etc.)
│   ├── service-deployments/    # Helm or Kustomize configs for model deployments
│   └── collab-logic/           # Logic for inter-agent communication & orchestration
│
├── data/                        # Data pipeline logic (ETL, tokenization, chunking, etc.)
│   ├── etl-pipeline/
│   └── example-datasets/
│
├── api/                         # API gateway and backend logic (Go or Python)
│   ├── routes/                 # Task submission endpoints
│   └── orchestration/          # Converts user requests into CRs for processing
│
├── examples/                    # Example workflows and scenarios
│   ├── question-answering/
│   ├── summarization-pipeline/
│   └── multi-model-chat/
│
├── docs/                        # Architecture diagrams and documentation
│   ├── architecture.md
│   ├── ollama-crd-spec.md
│   └── orchestration-diagram.png
│
└── README.md
```

---

## 🏗️ Infrastructure Stack

| Layer                | Technology                          | Purpose                                   |
|---------------------|--------------------------------------|-------------------------------------------|
| Container Runtime    | containerd                          | Lightweight, Kubernetes-native runtime    |
| GPU Provisioning     | NVIDIA GPU Operator                 | Automatically manage GPU drivers + toolkit |
| GitOps               | Flux                                | Declarative and auditable infra delivery  |
| K8s Package Manager  | Kustomize + Helm                    | Infra and app lifecycle management        |
| Model Hosting        | Ollama (on GPU nodes)               | LLM serving engine                        |
| Task Coordination    | Custom Resource Definitions (CRDs)  | Define and manage complex task orchestration |
| Monitoring           | Prometheus + Grafana (optional)     | Cluster and model performance observability |

---

## 🧩 Custom Resource Definitions (CRDs)

The system uses Kubernetes CRDs to implement the [A2A (Agent-to-Agent) protocol](https://github.com/google/A2A), enabling seamless communication between AI agents. Our CRDs define both the agent deployment and task orchestration aspects of the system.

### `OllamaAgent`

A CRD for deploying and managing individual model agents that implement the A2A protocol.

```yaml
apiVersion: ai.stack/v1alpha1
kind: OllamaAgent
metadata:
  name: summarizer-agent
spec:
  # Reference to the OllamaModelDefinition
  modelDefinition:
    name: summarizer-model
    version: "1.0.0"

  # Core agent configuration
  role: summarizer

  # A2A protocol implementation
  agentCard:
    capabilities:
      - summarization
      - text-analysis
    endpoint: "/api/v1/agent"
    authentication:
      type: "bearer"

  # Resource requirements
  resources:
    gpu: 1
    memory: "8Gi"
    cpu: "2"

  # A2A server configuration
  server:
    streaming: true
    pushNotifications: true
    webhookConfig:
      retryPolicy: exponential
      maxRetries: 3

  # Model-specific settings
  modelConfig:
    temperature: 0.7
    contextWindow: 4096
    responseFormat: "json"
```

### `OllamaModelDefinition`

A CRD that defines how to build a custom Ollama model with specific capabilities and behaviors. When created, it triggers the build process within the cluster.

```yaml
apiVersion: ai.stack/v1alpha1
kind: OllamaModelDefinition
metadata:
  name: summarizer-model
spec:
  # Base model configuration
  from: llama2

  # Model build parameters
  build:
    # System prompt defining agent behavior
    system: |
      You are a specialized summarization agent that excels at:
      1. Extracting key information from documents
      2. Creating concise summaries
      3. Identifying main themes and topics

    # Parameters for model behavior
    parameters:
      temperature: 0.7
      contextWindow: 4096
      responseFormat: json

    # Model adaptation and fine-tuning
    template: |
      {{ if .System }}{{.System}}{{ end }}

      Context: {{.Input}}

      Instructions: Create a summary that includes:
      - Main points
      - Key findings
      - Action items

      Response format:
      {{.ResponseFormat}}

    # Custom function definitions
    functions:
      - name: extract_key_points
        description: "Extract main points from the text"
        parameters:
          type: object
          properties:
            main_points:
              type: array
              items:
                type: string
            themes:
              type: array
              items:
                type: string

    # Model tags for versioning and identification
    tags:
      version: "1.0.0"
      type: "summarizer"
      capabilities: ["text-analysis", "summarization"]

    # Resource requirements for build process
    buildResources:
      gpu: 1
      memory: "16Gi"
      cpu: "4"

status:
  phase: Building # Building, Complete, Failed
  buildStartTime: "2025-04-23T13:30:00Z"
  lastBuildTime: "2025-04-23T13:35:00Z"
  modelHash: "sha256:abc123..."
  conditions:
    - type: Built
      status: "True"
      reason: "BuildSucceeded"
      message: "Model successfully built and registered"
```

### `TaskOrchestration`

A CRD that manages complex task workflows between multiple agents.

```yaml
apiVersion: ai.stack/v1alpha1
kind: TaskOrchestration
metadata:
  name: document-analysis
spec:
  # Task definition
  input:
    text: "Analyze and summarize this document"
    format: "text/plain"

  # A2A task workflow
  pipeline:
    - name: document-analyzer
      agentRef: analyzer-agent
      timeout: "5m"
      retries: 2
      artifacts:
        - name: analysis-result
          type: "application/json"

    - name: summarizer
      agentRef: summarizer-agent
      dependsOn: ["document-analyzer"]
      inputFrom:
        - taskRef: document-analyzer
          artifactName: analysis-result

    - name: quality-check
      agentRef: qa-agent
      dependsOn: ["summarizer"]
      condition: "success"

  # A2A protocol settings
  communication:
    streaming: true
    pushNotifications:
      enabled: true
      endpoint: "http://callback-service/webhook"

  # Output configuration
  output:
    storage:
      type: "s3"
      bucket: "ai-results"
      prefix: "outputs/"
    format:
      - type: "application/json"
      - type: "text/markdown"

  # Error handling
  errorPolicy:
    maxRetries: 3
    backoffLimit: 600
    failureAction: "rollback"
```

### Controller Implementation

The controllers implement the A2A protocol's core functionality:

1. **Agent Discovery**:
   - Automatically generates and manages `.well-known/agent.json` endpoints
   - Handles capability registration and updates
   - Manages agent metadata and health checks

2. **Task Management**:
   - Implements A2A task lifecycle (submitted → working → completed/failed)
   - Handles streaming updates via Server-Sent Events (SSE)
   - Manages task artifacts and state transitions

3. **Communication**:
   - Implements A2A message formats and parts
   - Handles both synchronous and streaming communication
   - Manages push notifications and webhooks

4. **Resource Orchestration**:
   - GPU allocation and scheduling
   - Memory and compute resource management
   - Model loading and unloading

---

## 🔍 Development Setup

### Development Environment

We provide a consistent development environment using VS Code Dev Containers. This ensures all developers have the same tools and versions.

1. **Prerequisites**:
   - [Docker](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/)
   - [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Getting Started**:
   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/fullStackOllama.git
   cd fullStackOllama

   # Open in VS Code
   code .

   # Click "Reopen in Container" when prompted
   # or use Command Palette (F1) -> "Remote-Containers: Reopen in Container"
   ```

The dev container includes:
- All required development tools
- Pre-configured pre-commit hooks
- VS Code extensions for Terraform, Go, and Kubernetes
- AWS and Kubernetes config mounting

Alternatively, if you prefer local installation:

### Pre-commit Hooks

This repository uses pre-commit hooks to ensure code quality and consistency. The following checks are performed before each commit:

1. **General Checks**
   - Trailing whitespace removal
   - End of file fixing
   - YAML syntax validation
   - Large file checks
   - Merge conflict detection
   - Private key detection

2. **Terraform Checks**
   - Format validation (`terraform fmt`)
   - Configuration validation (`terraform validate`)
   - Documentation updates
   - Security scanning (Checkov)
   - Linting (TFLint)

3. **Go Code Checks**
   - Format validation (`go fmt`)
   - Code analysis (`go vet`)
   - Comprehensive linting (golangci-lint)

4. **Custom Validations**
   - CRD syntax and structure validation
   - Model definition validation
   - Kubernetes resource validation

### Setup Instructions

1. Install pre-commit:
   ```bash
   brew install pre-commit
   ```

2. Install required tools:
   ```bash
   brew install terraform-docs tflint checkov
   go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
   ```

3. Install the pre-commit hooks:
   ```bash
   pre-commit install
   ```

4. (Optional) Run against all files:
   ```bash
   pre-commit run --all-files
   ```

### Continuous Integration

The same checks are run in CI/CD pipelines to ensure consistency. See the GitHub Actions workflows for details.

---

## 🏗️ Model Build Process

### GitOps Workflow

The model building process follows GitOps principles, ensuring that all changes are tracked, reviewed, and automatically deployed:

1. **Model Definition**
   ```yaml
   # models/summarizer/model.yaml
   apiVersion: ai.stack/v1alpha1
   kind: OllamaModelDefinition
   metadata:
     name: summarizer-model
   spec:
     from: llama2
     build:
       system: |
         You are a specialized summarization agent...
   ```

2. **Pull Request Flow**
   - Create branch: `feature/add-summarizer-model`
   - Add/modify model definition in `models/` directory
   - Create PR with changes
   - Automated validation:
     - YAML syntax
     - Model definition schema
     - Resource requirements check
     - Security scanning
   - PR review and approval
   - Merge to main branch

3. **Flux Synchronization**
   ```yaml
   # infra/base/models/kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - ../../models  # Watches the models directory
   ```
   - Flux detects changes in the `models/` directory
   - Applies new/modified OllamaModelDefinition to the cluster
   - Triggers the build controller

4. **Build Process**
   ```mermaid
   sequenceDiagram
     participant Flux
     participant API Server
     participant Build Controller
     participant Build Job
     participant Registry

     Flux->>API Server: Apply OllamaModelDefinition
     API Server->>Build Controller: Notify new/modified definition
     Build Controller->>Build Job: Create build job
     Build Job->>Build Job: Execute ollama create
     Build Job->>Registry: Push built model
     Build Job->>API Server: Update status
     Build Controller->>API Server: Update conditions
   ```

5. **Build Controller Actions**
   - Creates a Kubernetes Job for building
   - Mounts required GPU resources
   - Executes `ollama create` with definition
   - Monitors build progress
   - Updates status conditions
   - Handles failures and retries
   - Registers successful builds

6. **Model Registration**
   - Successful builds are registered in the cluster
   - Model becomes available for OllamaAgent instances
   - Version tracking and rollback support
   - Automatic cleanup of old versions

7. **Monitoring & Logs**
   ```yaml
   # Example build job logs
   2025-04-23T13:30:00Z [INFO] Starting build for summarizer-model
   2025-04-23T13:30:05Z [INFO] Downloading base model llama2
   2025-04-23T13:31:00Z [INFO] Applying model adaptations
   2025-04-23T13:32:00Z [INFO] Registering model summarizer-model:1.0.0
   2025-04-23T13:32:05Z [INFO] Build complete
   ```

### Security Considerations

- All model definitions are version controlled
- PR reviews ensure quality and security
- Base models are pulled from trusted sources
- Build jobs run in isolated environments
- Resource limits are strictly enforced
- Model provenance is tracked and verified

### Resource Management

- Build jobs are scheduled based on GPU availability
- Parallel builds are supported with resource quotas
- Failed builds are automatically cleaned up
- Successful builds are cached for reuse
- Version tags ensure reproducibility

---

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster with GPU-enabled nodes (AWS EKS, GKE, or bare-metal)
- NVIDIA GPU Operator installed
- Flux installed and watching this repository
- Kubectl + Kustomize + Helm
- Golang (for controller development)

### Deployment Steps

```bash
# 1. Bootstrap cluster
cd infra/overlays/dev
kustomize build . | kubectl apply -f -

# 2. Apply CRDs
kubectl apply -f crds/

# 3. Deploy example agents
kubectl apply -f ollama-operators/service-deployments/

# 4. Submit an orchestration task
kubectl apply -f examples/question-answering/task.yaml
```

---

## 📸 Diagrams

See `docs/architecture.md` and `docs/orchestration-diagram.png` for detailed system visuals.

---

## 🤝 Contributing

This project is a personal and professional showcase. However, contributors are welcome! PRs, Issues, and suggestions encouraged.

---

## 📚 Learning Goals

This project is also a journey of exploration. Through it, we aim to learn and demonstrate:

- GPU scheduling with Kubernetes
- Multi-agent AI orchestration
- Building CRDs and operators with Go
- Best practices in GitOps and cloud-native ML
- Open-source model hosting and scaling

---

## 📜 License

MIT License

---

## 🔗 Related Projects

- [NVIDIA GPU Operator](https://github.com/NVIDIA/gpu-operator)
- [Ollama](https://github.com/ollama/ollama)
- [Kubebuilder](https://book.kubebuilder.io/)
- [Kustomize](https://kustomize.io/)
- [Flux](https://fluxcd.io/)
