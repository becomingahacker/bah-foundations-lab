#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "cml_credentials" {
    value = { for user in module.users : user.cml_user => user.cml_password }
    sensitive = true
}