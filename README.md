# Terraform AWS Infrastructure + Jenkins CI/CD

A hands-on DevOps project demonstrating AWS infrastructure provisioning with **Terraform**, remote state management, reusable modules, multiple environments, Jenkins CI/CD, manual approval, and automated infrastructure drift detection.

## Project Overview

This project covers:

- Terraform infrastructure provisioning
- AWS provider configuration
- Remote Terraform state using Amazon S3
- VPC, EC2, Security Group, IAM and S3 resources
- Terraform modules
- DEV/STAGE environment separation
- Terraform state management and migration
- Infrastructure drift simulation and detection
- GitHub + Jenkins SSH integration
- Jenkins Terraform CI/CD
- Manual approval before `terraform apply`
- Scheduled automated drift detection

## Architecture

```text
                         +----------------------+
                         |       GitHub         |
                         | terraform-aws-lab    |
                         +----------+-----------+
                                    |
                              SSH / Deploy Key
                                    |
                                    v
                         +----------------------+
                         |       Jenkins        |
                         |                      |
                         | Checkout             |
                         | Terraform Init       |
                         | Validate             |
                         | Plan                 |
                         | Approval             |
                         | Apply                |
                         +----------+-----------+
                                    |
                           IAM Role Authentication
                                    |
                                    v
                         +----------------------+
                         |         AWS          |
                         |                      |
                         | VPC                  |
                         | EC2                  |
                         | Security Group       |
                         | IAM                  |
                         | S3                   |
                         +----------+-----------+
                                    |
                                    | Terraform State
                                    v
                         +----------------------+
                         |      S3 Backend      |
                         |                      |
                         | dev/terraform.tfstate|
                         | stage/terraform.tfstate
                         +----------------------+
```

## Project Structure

```text
terraform-aws-lab/
|
├── .gitignore
├── .terraform.lock.hcl
├── main.tf
├── variables.tf
├── outputs.tf
├── networking.tf
├── security.tf
├── iam.tf
├── ec2.tf
├── s3.tf
├── stage-only.tf
|
├── environments/
│   ├── dev.tfvars
│   └── stage.tfvars
|
└── modules/
    ├── ec2/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── iam/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── output.tf
    │
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── s3/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Technologies Used

| Technology | Purpose |
|---|---|
| AWS | Cloud infrastructure |
| Terraform | Infrastructure as Code |
| Amazon S3 | Terraform remote state |
| EC2 | Compute |
| VPC | Networking |
| IAM | Authentication and permissions |
| Security Groups | Network access control |
| GitHub | Source code management |
| Jenkins | CI/CD automation |
| Git SSH | Secure repository access |
| Linux | Server environment |
| Amazon Linux 2023 | EC2 operating system |

## 1. Terraform Installation

Terraform was installed on an Amazon Linux 2023 EC2 instance.

Verify:

```bash
terraform version
```

AWS authentication was provided through an EC2 IAM role.

Verify:

```bash
aws sts get-caller-identity
```

No AWS access keys were stored on the server.

## 2. AWS Provider Configuration

Terraform was configured for the `ap-south-1` region.

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key    = "terraform/dev/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

## 3. Remote Terraform Backend

Terraform state was moved from local state to an Amazon S3 backend.

Backend bucket:

```text
terraform-state-345485442601-1789473168
```

The bucket was configured with:

- Versioning enabled
- AES256 server-side encryption
- Separate state keys for environments

DEV:

```text
terraform/dev/terraform.tfstate
```

STAGE:

```text
terraform/stage/terraform.tfstate
```

### Why Remote State?

Terraform state represents Terraform's understanding of the infrastructure:

```text
Terraform configuration
        ↓
Terraform state
        ↓
Actual AWS infrastructure
```

Remote state provides a central state location that can be accessed by systems such as the Terraform EC2 instance and Jenkins.

## 4. AWS Infrastructure

The project provisions:

- VPC
- Subnet
- Security Group
- EC2
- IAM resources
- S3 application bucket

## 5. Terraform Modules

Reusable modules were created for:

```text
modules/
├── ec2/
├── iam/
├── networking/
└── s3/
```

Example:

```hcl
module "app_bucket" {
  source = "./modules/s3"

  bucket_name = "terraform-app-dev-ACCOUNT_ID"
  environment = var.environment
}
```

Modules provide:

- Reusability
- Organization
- Separation of responsibilities
- Easier maintenance
- Consistent infrastructure patterns

## 6. Multiple Environments

Environment-specific variable files:

```text
environments/
├── dev.tfvars
└── stage.tfvars
```

DEV:

```hcl
environment = "dev"
```

STAGE:

```hcl
environment = "stage"
```

Example:

```bash
terraform plan -var-file="environments/dev.tfvars"
```

or:

```bash
terraform plan -var-file="environments/stage.tfvars"
```

## 7. Environment State Isolation

DEV and STAGE use separate S3 state keys:

```text
S3 Backend
|
├── terraform/dev/terraform.tfstate
|
└── terraform/stage/terraform.tfstate
```

This keeps the environments isolated at the Terraform state level.

## 8. Terraform State Migration

During module refactoring, an existing S3 resource was moved from the root configuration into the S3 module.

The Terraform state address was changed with:

```bash
terraform state mv   aws_s3_bucket.app_bucket   module.app_bucket.aws_s3_bucket.this
```

`terraform state mv` changes the Terraform state address without recreating the actual AWS resource.

A subsequent:

```bash
terraform plan
```

was used to verify that Terraform did not unnecessarily recreate the bucket.

## 9. Infrastructure Drift

Infrastructure drift occurs when actual AWS infrastructure differs from what Terraform configuration declares.

For the exercise, the S3 bucket tag was intentionally changed outside Terraform.

Terraform expected:

```text
Name = Terraform App Bucket
```

AWS was changed to:

```text
Name = Drift-Test
```

Terraform then detected the difference.

### Important Drift Concept

Terraform cannot determine whether an external change was:

- accidental
- intentional
- temporary
- performed by another team

Terraform only detects the difference between the declared and actual infrastructure.

If a change is intentional, the desired state should normally be represented in Terraform configuration and committed to Git.

For attributes intentionally managed outside Terraform, `lifecycle.ignore_changes` can be used when appropriate.

## 10. GitHub Integration

Repository:

```text
https://github.com/powerstar7696-afk/terraform-aws-lab
```

Example Git workflow:

```bash
git add .
git commit -m "Initial Terraform AWS infrastructure"
git push origin main
```

## 11. GitHub SSH Authentication

Two separate SSH keys were used.

### Terraform EC2

Used for repository operations such as push, pull and clone.

### Jenkins EC2

Used for Jenkins repository access.

The Jenkins public key was configured in GitHub as a **Deploy Key** with write access disabled, giving Jenkins read-only repository access.

## 12. Jenkins Setup

A separate Jenkins EC2 instance was configured with:

- Amazon Linux 2023
- Java 21
- Jenkins
- Git
- Terraform
- AWS CLI

Verify:

```bash
git --version
terraform version
aws sts get-caller-identity
```

The Jenkins EC2 instance uses an IAM role for AWS authentication.

## 13. Jenkins Credentials

The Jenkins private SSH key was stored under:

```text
Manage Jenkins
    ↓
Credentials
    ↓
SSH Username with private key
```

Credential ID:

```text
github-terraform-ssh
```

The Jenkinsfile references:

```groovy
credentialsId: 'github-terraform-ssh'
```

The private key is therefore not stored directly inside the Jenkinsfile.

## 14. Jenkins Terraform CI/CD Pipeline

Pipeline flow:

```text
GitHub
   ↓
Checkout
   ↓
Terraform Init
   ↓
Terraform Validate
   ↓
Terraform Plan
   ↓
Manual Approval
   ↓
Terraform Apply
```

Pipeline:

```groovy
pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git(
                    url: 'git@github.com:powerstar7696-afk/terraform-aws-lab.git',
                    credentialsId: 'github-terraform-ssh',
                    branch: 'main'
                )
            }
        }

        stage('Terraform Version') {
            steps {
                sh 'terraform version'
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                    terraform init                       -backend-config="bucket=terraform-state-345485442601-1789473168"                       -backend-config="region=ap-south-1"                       -backend-config="key=terraform/dev/terraform.tfstate"
                '''
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var-file="environments/dev.tfvars"'
            }
        }

        stage('Approval') {
            steps {
                input message: 'Do you want to apply these Terraform changes?',
                      ok: 'Approve'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve -var-file="environments/dev.tfvars"'
            }
        }
    }
}
```

## 15. Manual Approval

The pipeline does not automatically apply every plan.

Flow:

```text
Terraform Plan
      ↓
Human Review
      ↓
Approve
      ↓
Terraform Apply
```

Jenkins uses the `input` step for human approval.

Terraform uses `-auto-approve` during the apply stage because Jenkins has already obtained the human approval.

## 16. Automated Drift Detection

A separate Jenkins job was created:

```text
terraform-drift-detection
```

The deployment and drift jobs have different purposes.

Deployment:

```text
Plan → Approval → Apply
```

Drift detection:

```text
Plan → Report drift
```

The drift detection pipeline does not automatically apply changes.

### Drift Detection Pipeline

```groovy
pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git(
                    url: 'git@github.com:powerstar7696-afk/terraform-aws-lab.git',
                    credentialsId: 'github-terraform-ssh',
                    branch: 'main'
                )
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                    terraform init                       -backend-config="bucket=terraform-state-345485442601-1789473168"                       -backend-config="region=ap-south-1"                       -backend-config="key=terraform/dev/terraform.tfstate"
                '''
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                script {

                    def exitCode = sh(
                        script: 'terraform plan -detailed-exitcode -var-file="environments/dev.tfvars"',
                        returnStatus: true
                    )

                    if (exitCode == 0) {
                        echo 'No drift detected.'
                    }
                    else if (exitCode == 2) {
                        error('Drift detected! Terraform configuration differs from AWS infrastructure.')
                    }
                    else {
                        error('Terraform plan failed.')
                    }
                }
            }
        }
    }
}
```

## 17. Terraform Detailed Exit Codes

With:

```bash
terraform plan -detailed-exitcode
```

Terraform returns:

| Exit Code | Meaning |
|---:|---|
| `0` | No changes |
| `1` | Terraform error |
| `2` | Changes detected |

Jenkins uses these values to distinguish a clean infrastructure state from detected changes.

## 18. Scheduled Drift Detection

The Jenkins drift job was configured using:

```text
Build Triggers
    ↓
Build periodically
```

Cron expression:

```text
H/5 * * * *
```

This runs the job approximately every five minutes.

Jenkins displayed:

```text
Started by timer
```

confirming that the scheduler was triggering the job.

## 19. Drift Detection Result

After the S3 bucket was intentionally modified outside Terraform, Jenkins detected the difference and produced:

```text
ERROR: Drift detected! Terraform configuration differs from AWS infrastructure.
```

The build finished:

```text
Finished: FAILURE
```

The failed build acts as an alert/signal for investigation. It does not automatically mean that the infrastructure change was incorrect.

## 20. Troubleshooting

### GitHub Host Key Verification Failed

Error:

```text
No ED25519 host key is known for github.com
Host key verification failed.
```

Cause:

Jenkins had not yet trusted GitHub's SSH host key.

Resolution:

```text
Manage Jenkins
    ↓
Security
    ↓
Git Host Key Verification Configuration
```

Configured:

```text
Accept first connection
```

After this, Jenkins successfully connected to GitHub.

### Jenkins Could Not Access GitHub

Test from the Jenkins server:

```bash
ssh -T git@github.com
```

Also verify that the GitHub Deploy Key and Jenkins private key belong to the same key pair.

### Terraform Backend Configuration

Jenkins has its own workspace:

```text
/var/lib/jenkins/workspace/terraform-aws-lab
```

The `.terraform/` directory is ignored by Git.

Therefore Jenkins explicitly initializes the backend:

```bash
terraform init   -backend-config="bucket=terraform-state-345485442601-1789473168"   -backend-config="region=ap-south-1"   -backend-config="key=terraform/dev/terraform.tfstate"
```

This avoids relying on previous workspace initialization.

### Provider Lock File

The repository contains:

```text
.terraform.lock.hcl
```

This file is committed to Git so Terraform can consistently select the locked provider version.

The AWS provider used in the project resolved to:

```text
hashicorp/aws v6.64.0
```

### EC2 Replacement Detected by Terraform

Terraform may show:

```text
-/+ aws_instance
```

or:

```text
must be replaced
```

when an instance attribute requiring replacement changes.

One situation encountered during this project was an Amazon Linux AMI data source using:

```hcl
most_recent = true
```

A newer AMI can therefore cause Terraform to detect an AMI change and propose replacement.

This was separate from the S3 drift exercise.

### S3 Bucket Replacement

S3 bucket names are immutable.

Changing the bucket name does not rename the existing AWS bucket.

Terraform must create a new bucket and destroy the old resource when the configuration requires it.

`terraform state mv` does not rename an actual AWS bucket; it only changes the resource address stored in Terraform state.

## 21. Security Considerations

AWS access keys were not stored in the Terraform project.

AWS authentication was provided through IAM roles attached to EC2.

The following should never be committed to Git:

```text
*.tfstate
*.tfstate.*
*.tfplan
AWS access keys
private SSH keys
passwords
secrets
API tokens
```

### .gitignore

```gitignore
# Terraform generated files
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log

# Secret variable files
*.tfvars.json

# OS / editor
.DS_Store
.vscode/
.idea/
```

The environment files in this project contain only environment configuration and no credentials.

## 22. Learning Outcomes

### Terraform

- Providers
- Resources
- Variables
- Outputs
- Data sources
- Modules
- State
- Remote backends
- State migration
- Multiple environments
- `terraform plan`
- `terraform apply`
- `terraform validate`
- Drift detection
- Detailed exit codes

### AWS

- VPC
- EC2
- S3
- IAM
- Security Groups
- AWS CLI
- IAM roles
- Remote Terraform state

### Jenkins

- Jenkins installation
- Pipeline as Code
- Git checkout
- SSH credentials
- Terraform execution
- Manual approval
- Scheduled jobs
- Automated drift detection

### GitHub

- Git repository management
- SSH authentication
- Deploy Keys
- Branch management
- Commit and push workflow

## 23. Complete Project Workflow

```text
STEP 1
Install Terraform
        ↓
STEP 2
Create Terraform Project
        ↓
STEP 3
Configure AWS Provider
        ↓
STEP 4
Create S3 Remote Backend
        ↓
STEP 5
Build AWS Infrastructure
(VPC + EC2 + SG + IAM + S3)
        ↓
STEP 6
Introduce Terraform Modules
        ↓
STEP 7
Create DEV/STAGE Environments
        ↓
STEP 8
Create Intentional AWS Drift
        ↓
STEP 9
Detect and Understand Drift
        ↓
STEP 10
Integrate Terraform with Jenkins
        ↓
STEP 11
Terraform Plan + Human Approval + Apply
        ↓
STEP 12
Automated Scheduled Drift Detection
        ↓
STEP 13
Document the Project
```

## 24. Key DevOps Concepts Demonstrated

The project demonstrates the transition from:

```text
Manual AWS Changes
```

to:

```text
Infrastructure as Code
```

and then to:

```text
Infrastructure as Code
        +
Version Control
        +
CI/CD
        +
Human Approval
        +
Automated Drift Detection
```

## Repository

GitHub:

```text
https://github.com/powerstar7696-afk/terraform-aws-lab
```

## Author

**Uday Kiran Reddi**

Hands-on AWS / DevOps / Terraform project focused on Infrastructure as Code, CI/CD automation, remote state management, and infrastructure drift detection.
