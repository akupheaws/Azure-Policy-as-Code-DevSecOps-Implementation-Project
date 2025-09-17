# Azure Compliance as Code — Terraform + OPA (Conftest) + GitHub Actions

Enforce cloud governance **before deploy** by checking your **Terraform plan** with **OPA/Rego** in CI. This repo provisions **8 Azure Linux VMs** and blocks non-compliant changes (missing tags, bad values, wide-open NSG rules).

## 🔩 What’s inside
- **Terraform**: 8 `azurerm_linux_virtual_machine` instances, VNet/Subnet, NSG, Public IPs, NICs.
- **OPA (Conftest)**: Rego policies enforce required tags & simple NSG hardening.
- **GitHub Actions**: 4-job pipeline — backend setup → format → plan → policy (optional gated apply).

## 📁 Structure
```
.
├─ README.md
├─ policies/
│  └─ tfplan/
│     ├─ tags_required.rego
│     ├─ tags_values.rego
│     └─ nsg_no_wide_open.rego
└─ terraform/
   ├─ backend.tf
   ├─ versions.tf
   ├─ providers.tf
   ├─ variables.tf
   ├─ main.tf
   └─ outputs.tf
```

## ✅ Requirements
- Terraform ≥ 1.5
- Azure CLI (`az`) locally, or just use GitHub Actions
- Conftest (optional locally; CI installs it)
- An SSH public key for VM login

## 🔐 GitHub Secrets (Repo → Settings → *Secrets and variables* → *Actions*)
- `AZURE_CREDENTIALS` → JSON from:
  ```bash
  az login
  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  az ad sp create-for-rbac     --name "gh-opa-terraform"     --role "Contributor"     --scopes "/subscriptions/$SUBSCRIPTION_ID"     --sdk-auth
  ```
  Paste the full JSON output into the secret.

## 🧱 Configure the remote backend
Edit `terraform/backend.tf` to match your names (the workflow can create them):
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "akuphetfstate1234" # must be globally unique, lowercase
    container_name       = "tfstate"
    key                  = "azure-compliance/terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

## ⚙️ Variables you’ll likely change
`terraform/variables.tf`
- `location` (default `eastus`)
- `resource_group_name` (default `rg-opa-demo`)
- `ssh_public_key` (set your public key)
- `allowed_ssh_cidr` (default `0.0.0.0/0` for demo; tighten in real use)
- `default_tags` (policy requires: `Environment`, `Owner`, `CostCenter`, `ComplianceClassification`)

You can put your values in `terraform/terraform.tfvars`:
```hcl
ssh_public_key      = "ssh-ed25519 AAAA... your_key"
allowed_ssh_cidr    = "203.0.113.0/24"
resource_group_name = "rg-opa-demo"
location            = "eastus"
default_tags = {
  Environment              = "dev"
  Owner                    = "you@example.com"
  CostCenter               = "CC-1234"
  ComplianceClassification = "Internal"
}
```

## 🧪 Policies (OPA/Rego)
- `tags_required.rego`: all VMs must have the 4 tags.
- `tags_values.rego`: validates `Environment` ∈ {dev, qa, stage, prod}, `CostCenter` matches `^CC-\d{4}$`, etc.
- `nsg_no_wide_open.rego`: blocks inbound SSH (22) or RDP (3389) from the world.

## 🧰 Local usage (optional)
```bash
cd terraform
terraform init -upgrade
terraform plan -out plan.out
terraform show -json plan.out > plan.json
# if you installed conftest locally:
conftest test plan.json --policy ../policies/tfplan
terraform apply plan.out
```

## 🤖 CI pipeline (GitHub Actions)
Workflow file: `.github/workflows/azure-tf-opa.yml`

Jobs:
1. **backend_setup** — ensures the tfstate RG, storage account, and container exist.
2. **fmt** — auto-formats Terraform on PRs (commits changes), then enforces `fmt -check -diff`.
3. **plan** — runs `init`, `validate`, `plan`, exports `plan.json`, uploads artifacts.
4. **policy_and_apply** — runs Conftest on `plan.json`; optional **gated apply** via `workflow_dispatch` on `main`.

### Gated apply
To deploy from CI, run the workflow manually (Actions tab) with:
- `apply = true`
- on branch `main`

CI will apply the **same** `plan.out` that passed policy.

## 🧹 Cleanup
```bash
cd terraform
terraform destroy -auto-approve
```

## 🛠 Troubleshooting
- **Login fails in CI**: ensure `AZURE_CREDENTIALS` is valid and SP has rights.
- **Backend init errors**: confirm RG/storage/container match `backend.tf` names; the `backend_setup` job creates them.
- **Policy failures**: check CI logs; Rego `deny` messages will name the violating resource and rule.
