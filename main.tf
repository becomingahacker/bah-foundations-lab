#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg_file = file("config.yml")
  cfg      = yamldecode(local.cfg_file)
}

module "secret" {
  source = "./module-cml2-secrets"
  cfg    = local.cfg_file
}

module "user" {
  source      = "./module-cml2-users"
  count       = local.cfg.pod_count
  username    = "pod${count.index + 1}"
  fullname    = "Pod ${count.index + 1} Student"
  description = "Pod ${count.index + 1} Student"
  email       = "pod${count.index + 1}@${local.cfg.domain_name}"
  is_admin    = false
}

module "pod" {
  source     = "./module-cml2-foundations-lab"
  count      = local.cfg.pod_count
  title      = "Becoming a Hacker Foundations - Pod ${format("%02d", count.index + 1)}"
  pod_number = count.index + 1
}

module "group" {
  source      = "./module-cml2-group"
  count       = local.cfg.pod_count
  group_name  = format("pod%d", count.index + 1)
  description = format("Permission group for pod%d", count.index + 1)
  member_ids  = [module.user[count.index].user_id]
  lab_ids     = [module.pod[count.index].lab_id]
  permission = "read_write"
}
