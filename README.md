# repo-deploy

`repo-deploy` is a centralized GitHub repository template and deployment driver for cloud-based infrastructure-as-code projects. It provides a standard structure for bootstrapping new repositories and integrating them into a shared CI/CD system with reusable GitHub Actions workflows and linting logic.

## THIS IS VERY MUCH A WORK IN PROGRESS AND NOT READY FOR PRODUCTION USE. 

## 🌐 Supported Cloud Providers

- [x] AWS (via CloudFormation)
- [ ] Azure (stubbed for future)
- [ ] GCP (stubbed for future)

## 📦 What It Does

- Bootstraps new repositories using CLI with provider-specific templates
- Automatically creates directory structure and starter files
- Configures `.github/workflows/deploy.yaml` to:
  - Install and run selected linters
  - Deploy cloud resources using defined templates
- Centralizes shared linting logic via `scripts/linters/`
- Allows updating of `.github/workflows/deploy.yaml` and other pertenent settings from a central location

## 🚀 Quick Start

### Clone this repo
```bash
git clone https://github.com/your-org/repo-deploy
cd repo-deploy
```
### Bootstrap a new repo (interactive or scripted)
```bash
./run-bootstrap.sh example-repo aws "yaml,cloudformation" "Demo repo using repo-deploy" ~/git/example-repo
```
### This will:
- ✅ Create a new repo directory at the specified destination
- ✅ Initialize it with provider-specific templates (e.g., CloudFormation under deploy/cloudformation/)
- ✅ Add a .linters file with selected linters (e.g., yaml, cloudformation)
- ✅ Add .github/workflows/deploy.yaml that:
- ✅ Installs only the requested linters
- ✅ Calls scripts/run_linters.sh to run them
- ✅ Sets up a basic CI/CD pipeline for the new repo
- ✅ Deploy to AWS using the CloudFormation templates supplied with configuration from the repo.toml file

### 🛠️ Linters Supported
- yaml → yamllint
- cloudformation → cfn-lint
- shell → ShellCheck
- ansible → ansible-lint
- terraform → terraform fmt
- puppet → puppet-lint
- ruby → rubocop
- python → pylint
- markdown → markdownlint-cli
- cfn-nag → cfn_nag

### 🧰 Scripts Overview
```bash
scripts/
├── run_linters.sh            # Dispatcher for selected linters
└── linters/
    ├── lint_yaml.sh
    ├── lint_cloudformation.sh
    └── ...                   # See full list above
```
### 📁 Directory Layout (Example Repo)
```bash
.
├── .github/
│   └── workflows/
│       └── deploy.yaml       # Auto-generated workflow
├── deploy/
│   └── cloudformation/       # AWS CloudFormation templates
├── scripts/
│   ├── run_linters.sh
│   └── linters/
├── .linters                  # List of linters for this repo
├── README.md
├── Makefile                  # Optional Makefile for convenience
├── repo.toml                 # TOML file for repo metadata
```

### 🧪 Roadmap
- Auto-push updates to deploy.yaml from repo-deploy
- Azure and GCP support
- Template validation for each cloud provider
- Web-based repo creation via GitHub issue forms
- Multi-account support (e.g., AWS Organizations, Azure Management Groups, GCP Organizations)
- Support for multiple environments (dev, staging, prod)
- Integration with Terraform, Pulumi, and other IaC tools
- API support for retreiving repo metadata and objects from cloud providers to use in workflows and templates

⸻

Built by @bryanfrye
