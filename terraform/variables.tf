variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Workload resource group"
  default     = "rg-opa-demo"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for admin user"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH (demo default is wide; lock down in real use)"
  default     = "0.0.0.0/0"
}

# Default, compliant tags (OPA enforces presence/values)
variable "default_tags" {
  type = map(string)
  default = {
    Environment              = "dev"
    Owner                    = "platform-team@example.com"
    CostCenter               = "CC-1234"
    ComplianceClassification = "Internal"
  }
}
