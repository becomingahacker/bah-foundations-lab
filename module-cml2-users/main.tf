#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg = yamldecode(var.cfg)
}

resource "random_pet" "pod_password" {
  length = 3
}

resource "cml2_user" "pod_user" {
  username    = "pod${var.pod_number}"
  password    = resource.random_pet.pod_password.id
  fullname    = "Pod ${var.pod_number} Student"
  description = "Pod ${var.pod_number} Student"
  email       = "pod${var.pod_number}@${local.cfg.domain_name}"
  is_admin    = false
}
