
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
│   └── taskorchestration_crd.yaml
│
├── controllers/                 # Golang operators/controllers (kubebuilder-based)
│   ├── ollamaagent_controller.go
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

### `OllamaAgent`

A CRD for deploying and tracking a specific model service.

```yaml
apiVersion: ai.stack/v1alpha1
kind: OllamaAgent
metadata:
  name: summarizer-agent
spec:
  model: llama3
  role: summarizer
  resources:
    gpu: 1
    memory: "8Gi"
    cpu: "2"
  endpoint: "/summarize"
  env:
    - name: TEMPERATURE
      value: "0.7"
```

### `TaskOrchestration`

A CRD for assigning collaborative tasks to a group of agents.

```yaml
apiVersion: ai.stack/v1alpha1
kind: TaskOrchestration
metadata:
  name: answer-and-summarize
spec:
  inputText: "Summarize and answer questions based on this document."
  pipeline:
    - agentRef: qna-agent
    - agentRef: summarizer-agent
  outputTarget: s3://ai-results/outputs/
```

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
