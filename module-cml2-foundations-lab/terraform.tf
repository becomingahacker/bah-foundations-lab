#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    cml2 = {
      source = "CiscoDevNet/cml2"
    }
  }
  required_version = ">= 1.1.0"
}
