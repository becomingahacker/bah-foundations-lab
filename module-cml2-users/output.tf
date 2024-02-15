#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "username" {
  value = cml2_user.pod_user.username
}

output "password" {
  value     = random_pet.pod_password.id
  sensitive = true
}

output "user_id" {
  value = cml2_user.pod_user.id
}
