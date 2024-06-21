#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "username" {
  value = cml2_user.pod_user.username
}

output "password" {
  value     = var.password == "" ? random_pet.pod_password.id : var.password
  sensitive = true
}

output "user_id" {
  value = cml2_user.pod_user.id
}
