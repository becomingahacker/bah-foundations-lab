#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg = yamldecode(var.cfg)
}

resource "random_pet" "cml_password" {
  count = local.cfg.pod_count
}

resource "cml2_user" "pod_user" {
  count       = local.cfg.pod_count
  username    = "pod${count.index + 1}"
  password    = resource.random_pet.cml_password[count.index].id
  fullname    = "Pod ${count.index + 1} Student"
  description = "Pod ${count.index + 1} Student"
  email       = "pod${count.index + 1}@${local.cfg.domain_name}"
  is_admin    = false
}
