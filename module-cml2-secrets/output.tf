#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "conjur_secrets" {
  value = { for k, v in data.conjur_secret.conjur_secret : k => v.value }
}
