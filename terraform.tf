#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    cml2 = {
      source  = "CiscoDevNet/cml2"
      version = "~>0.7.0"
    }
  }

  required_version = ">= 1.1.0"

  backend "gcs" {
    bucket = "bah-cml-terraform-state"
    prefix = "bah-foundations-lab/state"
  }
}

provider "cml2" {
  address        = "https://${local.cfg.lb_fqdn}"
  username       = local.cfg.app.user
  password       = module.secret.conjur_secrets[local.cfg.app.pass]
  use_cache      = false
  skip_verify    = false
  dynamic_config = true
}
