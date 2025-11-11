# Core Cloud GitHub Enterprise Terraform Module

This repository contains the core Terraform modules for the Core Cloud Github Enterprise.

## Repository Structure

```text
── .github
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── labels.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows
│       ├── pull-request-sast.yaml
│       ├── pull-request-semver-label-check.yaml
│       └── pull-request-semver-tag-merge.yaml
├── catalog-info.yaml
├── CODE_OF_CONDUCT.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── modules
│   └── core-cloud-ghes-terraform
│       ├── main.tf
│       ├── outputs.tf
│       ├── README.md
│       └── variables.tf
└── README.md
```

The following modules are available:

- [AWS](./modules/aws/README.md) # Need to update this part to include path to the modules directory

## Example Usage
Example usage can be found in the README of the module. 


## Static Analysis and Code Quality

This repository is automatically scanned by `Checkov` and `SonarQube` through GitHub Actions workflows located in `.github/workflows/checkov-sonar-scan.yaml`

### Checkov Security and Compliance Scan

* Runs on every *Pull Request* and *push* to `main` that modifies files under `modules/core-cloud-ghes-terraform/`.

* Uses the internal reusable workflow: `UKHomeOffice/core-cloud-workflow-checkov-sast-scan@1.7.0.`

* Performs Infrastructure-as-Code (IaC) *security, compliance, and policy validation* against Terraform configurations.

Results are visible under the **Actions** tab in the job summary (and optionally in GitHub’s **Code Scanning Alerts** view).

### SonarQube Code Quality Scan

* Uses the internal action: `UKHomeOffice/core-cloud-workflow-sonarqube-scan@1.1.4.`

* Analyzes Terraform code quality, maintainability, and duplication metrics for the `modules/core-cloud-ghes-terraform directory`.

* The scan results are available in the **SonarQube dashboard** at:
🔗 https://sonarqube.cc-platform-ops-tooling-live-1.core.homeoffice.gov.uk

### Enforcement Level

* Both **Checkov** and **SonarQube** currently run in **advisory** mode.

    * Checkov: reports policy violations but does not **block merges** in this repository.

    * SonarQube: quality gate status is evaluated but **not enforced** as a merge gate.

* These scans provide early visibility into security and quality issues in shared Terraform modules consumed by other infrastructure repositories.

### Semantic Versioning and Trivy Scan
In addition to static analysis, this repository enforces semantic versioning and performs Terraform validation using Trivy.
The following GitHub Actions workflows manage version control hygiene and code validation:

| Workflow File                                                                                                      | Purpose                                                                                                                            |
| :----------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| [`.github/workflows/pull-request-sast.yaml`](.github/workflows/pull-request-sast.yaml)                             | Runs a **Trivy** scan to validate Terraform syntax and detect security misconfigurations in pull requests.                         |
| [`.github/workflows/pull-request-semver-label-check.yaml`](.github/workflows/pull-request-semver-label-check.yaml) | Ensures each pull request includes an appropriate **Semantic Version (SemVer)** label (`major`, `minor`, or `patch`) before merge. |
| [`.github/workflows/pull-request-semver-tag-merge.yaml`](.github/workflows/pull-request-semver-tag-merge.yaml)     | Automatically applies a **SemVer tag** to the main branch when changes are merged, enabling versioned module releases.             |

### How It Works

* When a pull request is opened, **Trivy** validates Terraform code and scans for common vulnerabilities.

* The **SemVer label check** ensures versioning discipline is maintained across releases.

* Upon merge to `main`, a **SemVer tag** is generated (e.g., `v1.5.0`), which can then be referenced by   Terragrunt and other consumer repositories via:

```hcl
terraform {
  source = "git::https://github.com/UKHomeOffice/core-cloud-github-enterprise-terraform//?ref=v1.5.0"
}
```
📈 CI/CD Flow Overview

graph LR
  A[Pull Request Opened] --> B[Trivy Validation (SAST)]
  A --> C[Checkov Scan]
  A --> D[SonarQube Scan]
  B --> E[SemVer Label Check]
  C --> E
  D --> E
  E --> F[Merge to main]
  F --> G[SemVer Tag Applied]

### Flow Summary:
Pull requests trigger Trivy, Checkov, and SonarQube scans for validation and quality checks.
After successful scans and a SemVer label verification, merges to main automatically create a semantic version tag, ready to be consumed by downstream Terragrunt configurations.