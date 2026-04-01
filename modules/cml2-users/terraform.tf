#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    cml2 = {
      source  = "registry.terraform.io/CiscoDevNet/cml2"
      version = "0.9.0-beta3"
    }
  }
  required_version = ">= 1.1.0"
}
