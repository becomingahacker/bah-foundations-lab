#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "pod_ipv4_address" {
  value = google_compute_address.c8k_ipv4_pod_address[*].address
}

output "pod_ipv6_prefix" {
  value = google_compute_forwarding_rule.c8k_forwarding_rule_byoipv6[*].ip_address
}

output "pod_ipv6_prefix_length" {
  value = 96
}
