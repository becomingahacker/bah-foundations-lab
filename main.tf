#
# This file is part of Cisco Modeling Labs
# Copyright (c) 2019-2023, Cisco Systems, Inc.
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
  source = "./module-cml2-users"
  cfg    = local.cfg_file
}

module "lab" {
  source = "./module-cml2-foundations-lab"
  count = local.cfg.pod_count
  title = "Becoming a Hacker Foundations - Pod ${count.index + 1}"
}
