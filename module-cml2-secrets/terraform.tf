#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    conjur = {
      source  = "localhost/cyberark/conjur"
      version = "0.6.7"
    }
  }
  required_version = ">= 1.1.0"
}
