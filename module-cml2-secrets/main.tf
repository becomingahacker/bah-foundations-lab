#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg = yamldecode(var.cfg)
}

data "conjur_secret" "conjur_secret" {
  for_each = toset(local.cfg.secrets)
  name     = each.value
}
