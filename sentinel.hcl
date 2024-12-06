# Ensure no security groups allow ingress from 0.0.0.0/0 to port 22
policy "deny-public-ssh-acl-rules" {
  source = "./tests/policy/deny-public-ssh-acl-rules.sentinel"
  enforcement_level = "advisory"
}

# Ensure no security groups allow ingress from 0.0.0.0/0 to port 3389
policy "deny-public-rdp-acl-rules" {
  source = "./tests/policy/deny-public-rdp-acl-rules.sentinel"
  enforcement_level = "advisory"
}

# Ensure the default security group of every VPC restricts all traffic
policy "restrict-all-vpc-traffic-acl-rules" {
  source = "./tests/policy/restrict-all-vpc-traffic-acl-rules.sentinel"
  enforcement_level = "advisory"
}
