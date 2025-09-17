package tfplan.tags_required

required := {"Environment","Owner","CostCenter","ComplianceClassification"}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_linux_virtual_machine"
  after := rc.change.after
  missing := required - object.keys(after.tags)
  count(missing) > 0
  msg := sprintf("%s: missing required tags: %v", [rc.address, missing])
}
