#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  raw_cfg = yamldecode(file(var.cfg_file))
  cfg = merge(
    {
      for k, v in local.raw_cfg : k => v if k != "secret"
    },
    {
      secrets = module.secrets.secrets
    }
  )
  extras = var.cfg_extra_vars == null ? "" : (
    fileexists(var.cfg_extra_vars) ? file(var.cfg_extra_vars) : var.cfg_extra_vars
  )
  passwords_override = fileexists("${path.root}/cml_credentials.json") ? jsondecode(file("${path.root}/cml_credentials.json")) : {}
}

module "secrets" {
  source = "./modules/secrets"
  cfg    = local.raw_cfg
}

module "user" {
  source      = "./modules/cml2-users"
  count       = local.cfg.pod_count
  username    = "bahf-pod${count.index + 1}"
  password    = lookup(local.passwords_override, "bahf-pod${count.index + 1}", "")
  fullname    = "BAH Foundations Pod ${count.index + 1} Student"
  description = "BAH Foundations Pod ${count.index + 1} Student"
  email       = "bahf-pod${count.index + 1}@${local.cfg.domain_name}"
  is_admin    = false
}

module "pod" {
  source                    = "./modules/cml2-foundations-lab"
  count                     = local.cfg.pod_count
  title                     = format("Becoming a Hacker Foundations - Pod %02d", count.index + 1)
  pod_number                = count.index + 1
  ip_prefix                 = cidrsubnet("10.0.0.0/8", 8, count.index + 1)
  global_ipv4_address       = cidrhost(local.cfg.cml.global_ipv4_prefix, count.index + 1)
  global_ipv4_netmask       = cidrnetmask(local.cfg.cml.global_ipv4_prefix)
  global_ipv6_prefix        = cidrsubnet(local.cfg.cml.global_ipv6_prefix, 8, count.index + 1)
  global_ipv6_address       = cidrhost(cidrsubnet(local.cfg.cml.global_ipv6_prefix, 8, 0), count.index + 1)
  global_ipv6_prefix_length = 64
  bgp_ipv6_peer             = local.cfg.cml.bgp_ipv6_peer
  bgp_ipv4_peer             = local.cfg.cml.bgp_ipv4_peer
  internet_mtu              = 1500
  # HACK - use the same domain name for all pods
  #pod_domain_name               = format("bahf-pod%d.%s", count.index + 1, local.cfg.domain_name)
  domain_name = local.cfg.pod_domain_name
}

module "group" {
  source      = "./modules/cml2-group"
  count       = local.cfg.pod_count
  group_name  = format("bahf-pod%d", count.index + 1)
  description = format("Permission group for bahf-pod%d", count.index + 1)
  member_ids  = [module.user[count.index].user_id]
  lab_ids     = [module.pod[count.index].lab_id]
  permission  = "read_write"
}
