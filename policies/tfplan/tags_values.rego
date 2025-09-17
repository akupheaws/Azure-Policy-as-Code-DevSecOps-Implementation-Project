package tfplan.tags_values

valid_envs := {"dev","qa","stage","prod"}
valid_classes := {"Public","Internal","PII","PCI"}
costcenter_re := `^CC-\d{4}$`

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_linux_virtual_machine"
  t := rc.change.after.tags
  not valid_env(t["Environment"])
  msg := sprintf("%s: Environment must be one of %v", [rc.address, valid_envs])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_linux_virtual_machine"
  t := rc.change.after.tags
  not valid_owner(t["Owner"])
  msg := sprintf("%s: Owner must be non-empty", [rc.address])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_linux_virtual_machine"
  t := rc.change.after.tags
  not valid_costcenter(t["CostCenter"])
  msg := sprintf("%s: CostCenter must match %s", [rc.address, costcenter_re])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_linux_virtual_machine"
  t := rc.change.after.tags
  not valid_class(t["ComplianceClassification"])
  msg := sprintf("%s: ComplianceClassification must be one of %v", [rc.address, valid_classes])
}

valid_env(v)    { v != null; valid_envs[v] }
valid_owner(v)  { v != null; trim(v) != "" }
valid_costcenter(v) { v != null; re_match(costcenter_re, v) }
valid_class(v)  { v != null; valid_classes[v] }
trim(s) = t { t := trim_space(s) }
