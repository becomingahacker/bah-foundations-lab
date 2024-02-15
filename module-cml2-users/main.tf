#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

resource "random_pet" "pod_password" {
  length = 3
}

resource "cml2_user" "pod_user" {
  username    = var.username
  password    = resource.random_pet.pod_password.id
  fullname    = var.fullname
  description = var.description
  email       = var.email
  is_admin    = var.is_admin
}
