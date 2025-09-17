package tfplan.nsg_no_wide_open

# Block inbound SSH/RDP from 0.0.0.0/0 or '*'
is_world(s) {
  s == "0.0.0.0/0"
} else {
  s == "*"
} else {
  s == "Any"
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_network_security_group"
  rules := rc.change.after.security_rule
  some i
  r := rules[i]
  lower(r.direction) == "inbound"
  lower(r.access) == "allow"
  r.destination_port_range == "22"
  is_world(r.source_address_prefix)
  msg := sprintf("%s: NSG allows SSH from world: %v", [rc.address, r.name])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_network_security_group"
  rules := rc.change.after.security_rule
  some i
  r := rules[i]
  lower(r.direction) == "inbound"
  lower(r.access) == "allow"
  r.destination_port_range == "3389"
  is_world(r.source_address_prefix)
  msg := sprintf("%s: NSG allows RDP from world: %v", [rc.address, r.name])
}
