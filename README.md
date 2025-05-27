# repo-deploy

`repo-deploy` is a centralized GitHub repository template and deployment driver for cloud-based infrastructure-as-code projects. It provides a standard structure for bootstrapping new repositories and integrating them into a shared CI/CD system with reusable GitHub Actions workflows and linting logic.

## 🌐 Supported Cloud Providers

- [x] AWS (via CloudFormation)
- [ ] Azure (stubbed for future)
- [ ] GCP (stubbed for future)

## 📦 What It Does

- Bootstraps new repositories using a Q&A interface
- Automatically creates directory structure and starter files
- Installs cloud-specific templates (e.g., CloudFormation for AWS)
- Configures `.github/workflows/deploy.yaml` to:
  - Install and run selected linters
  - Deploy cloud resources using defined templates
- Centralizes shared linting logic via `scripts/linters/`
- Uses a `.linters` file to dynamically configure linting per repo

## 🚀 Quick Start

# Clone this repo
```bash
git clone https://github.com/your-org/repo-deploy
cd repo-deploy
```
# Bootstrap a new repo (interactive or scripted)
./run-bootstrap.sh example-repo aws "yaml,cloudformation" "Demo repo using repo-deploy" ~/git/example-repo

This will:
	•	✅ Create a new repo directory at the specified destination
	•	✅ Initialize it with provider-specific templates (e.g., CloudFormation under deploy/cloudformation/)
	•	✅ Add a .linters file with selected linters (e.g., yaml, cloudformation)
	•	✅ Add .github/workflows/deploy.yaml that:
	•	Installs only the requested linters
	•	Calls scripts/run_linters.sh to run them

🛠️ Linters Supported
	•	yaml → yamllint
	•	cloudformation → cfn-lint
	•	shell → ShellCheck
	•	ansible → ansible-lint
	•	terraform → terraform fmt
	•	puppet → puppet-lint
	•	ruby → rubocop
	•	python → pylint
	•	markdown → markdownlint-cli

🧰 Scripts Overview
scripts/
├── run_linters.sh            # Dispatcher for selected linters
└── linters/
    ├── lint_yaml.sh
    ├── lint_cloudformation.sh
    └── ...                   # See full list above
📁 Directory Layout (Example Repo)
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
└── README.md
🧪 Roadmap
	•	Auto-push updates to deploy.yaml from repo-deploy
	•	Azure and GCP support
	•	Template validation for each cloud provider
	•	Web-based repo creation via GitHub issue forms

⸻

Built by @bryanfrye
