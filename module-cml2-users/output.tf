#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "cml_user" {
  value = cml2_user.pod_user.username
}

output "cml_password" {
  value = random_pet.pod_password.id
  sensitive = true
}
