#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

resource "cml2_group" "pod_group" {
  description = var.description
  name        = var.group_name
  members     = var.member_ids
  labs        = [for id in var.lab_ids : { id = id, permission = var.permission }]
}
