# Terraform Workspaces Practice

Learn how to manage multiple environments (dev, staging, prod) using Terraform workspaces with the same codebase.

---

## 🚀 Quick Setup

### Option 1: Cloud Shell (Recommended)

```bash
# Already authenticated!
git clone <YOUR_REPO_URL>
cd terraform-workspaces-practice
```

### Option 2: Local Setup

**Authenticate first:**
```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**Clone the repo:**
```bash
git clone <YOUR_REPO_URL>
cd terraform-workspaces-practice
```

---

## ⚙️ Configuration

**Edit `terraform.tfvars`:**
```hcl
project_id = "your-actual-project-id"  # Change this!
```

**Enable required APIs:**
```bash
gcloud services enable compute.googleapis.com storage.googleapis.com
```

---

## 🎯 Workspace Workflow

### Step 1: Initialize Terraform

```bash
terraform init
```

### Step 2: Check Current Workspace

```bash
# You start in the 'default' workspace
terraform workspace show
```

### Step 3: Create Dev Environment

```bash
# Create and switch to dev workspace
terraform workspace new dev

# Verify you're in dev
terraform workspace show

# Deploy dev infrastructure
terraform plan
terraform apply
# Type 'yes'
```

**What gets created in DEV:**
- 1 small VM (e2-micro)
- VPC with subnet (10.0.1.0/24)
- Storage bucket
- Firewall rules
- 10GB disk

### Step 4: Create Staging Environment

```bash
# Create and switch to staging workspace
terraform workspace new staging

# Deploy staging infrastructure
terraform apply
# Type 'yes'
```

**What gets created in STAGING:**
- 2 VMs (e2-small)
- VPC with subnet (10.0.2.0/24)
- Storage bucket
- Firewall rules
- 20GB disk

### Step 5: Create Production Environment

```bash
# Create and switch to prod workspace
terraform workspace new prod

# Deploy production infrastructure
terraform apply
# Type 'yes'
```

**What gets created in PROD:**
- 3 VMs (e2-medium)
- VPC with subnet (10.0.3.0/24)
- Storage bucket
- Firewall rules
- 50GB disk

### Step 6: View All Workspaces

```bash
# List all workspaces
terraform workspace list

# You should see:
#   default
#   dev
#   staging
# * prod    (asterisk shows current workspace)
```

---

## 🔄 Switching Between Workspaces

```bash
# Switch to dev
terraform workspace select dev

# View dev resources
terraform state list

# Switch to staging
terraform workspace select staging

# View staging resources
terraform state list

# Switch to prod
terraform workspace select prod

# View prod resources
terraform state list
```

**Notice:** Each workspace has completely separate resources!

---

## 🌐 Test the Web Servers

After each deployment, get the instance IPs:

```bash
# Get output for current workspace
terraform output web_urls

# Visit the URLs in your browser
# Each shows which environment it's in!
```

**You'll see:**
- **Dev** = Blue background, 1 server
- **Staging** = Orange background, 2 servers  
- **Prod** = Green background, 3 servers

---

## 📊 Compare Environments

```bash
# See environment summary for each workspace

terraform workspace select dev
terraform output environment_summary

terraform workspace select staging
terraform output environment_summary

terraform workspace select prod
terraform output environment_summary
```

---

## 🔍 Understanding Workspace State Storage

**Local state storage:**
```bash
# View the state directory structure
ls -la terraform.tfstate.d/

# You'll see:
# terraform.tfstate.d/
# ├── dev/
# │   └── terraform.tfstate
# ├── staging/
# │   └── terraform.tfstate
# └── prod/
#     └── terraform.tfstate
```

**Each workspace has its own state file!**

---

## 🎓 Practice Exercises

### Exercise 1: Make a Change in Dev First

```bash
# Switch to dev
terraform workspace select dev

# Edit main.tf - change instance_count for dev to 2
# (In locals block, change dev instance_count from 1 to 2)

# Apply the change
terraform apply

# Verify staging and prod are unaffected
terraform workspace select staging
terraform state list  # Still 2 instances

terraform workspace select prod
terraform state list  # Still 3 instances
```

### Exercise 2: Workspace Promotion Workflow

```bash
# 1. Test in dev
terraform workspace select dev
terraform apply

# 2. Promote to staging
terraform workspace select staging
terraform apply

# 3. After validation, promote to prod
terraform workspace select prod
terraform apply
```

### Exercise 3: Find Resources in GCP Console

Go to GCP Console and find:
- **Compute Engine** → See VMs named: `app-dev-1`, `app-staging-1`, `app-staging-2`, `app-prod-1`, etc.
- **VPC Networks** → See: `vpc-dev`, `vpc-staging`, `vpc-prod`
- **Storage** → See buckets for each environment

---

## 🧹 Cleanup

**Destroy each environment separately:**

```bash
# Destroy dev
terraform workspace select dev
terraform destroy
# Type 'yes'

# Destroy staging
terraform workspace select staging
terraform destroy
# Type 'yes'

# Destroy prod
terraform workspace select prod
terraform destroy
# Type 'yes'
```

**Delete workspaces (after destroying resources):**

```bash
# Switch to default first
terraform workspace select default

# Delete empty workspaces
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod
```

---


## 🆘 Troubleshooting

**"Workspace already exists":**
```bash
# Just select it instead
terraform workspace select dev
```

**"Cannot delete workspace with resources":**
```bash
# Destroy resources first
terraform destroy
# Then delete workspace
terraform workspace delete dev
```

**"Wrong workspace" - Applied to prod by accident:**
```bash
# Always check before applying!
terraform workspace show

# If you made a mistake, destroy and switch
terraform destroy
terraform workspace select dev
```

**Forgot which workspace you're in:**
```bash
# Check current workspace
terraform workspace show

# Or list all with asterisk on current
terraform workspace list
```

---

## 🎯 Key Commands Reference

```bash
# Workspace management
terraform workspace list          # List all workspaces
terraform workspace show          # Show current workspace
terraform workspace new <name>    # Create new workspace
terraform workspace select <name> # Switch to workspace
terraform workspace delete <name> # Delete empty workspace

# Always verify before applying!
terraform workspace show
terraform plan
terraform apply
```

---

## 💡 Best Practices

1. **Always check workspace before applying:**
   ```bash
   terraform workspace show
   ```

2. **Use consistent naming:**
   - Resources: `app-${terraform.workspace}-1`
   - Networks: `vpc-${terraform.workspace}`

3. **Test in dev first:**
   - dev → staging → prod workflow

4. **Document workspace strategy:**
   - Who can deploy to which workspace?
   - What's different between environments?

5. **Use locals for environment config:**
   - Centralized configuration
   - Easy to modify

---
