#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg_file = file("config.yml")
  cfg      = yamldecode(local.cfg_file)
}

module "secrets" {
  source = "./module-cml2-secrets"
  cfg    = local.cfg_file
}

module "users" {
  source     = "./module-cml2-users"
  count      = local.cfg.pod_count
  cfg        = local.cfg_file
  pod_number = count.index + 1
}

module "lab" {
  source = "./module-cml2-foundations-lab"
  count  = local.cfg.pod_count
  title  = "Becoming a Hacker Foundations - Pod ${format("%02d", count.index + 1)}"
}
