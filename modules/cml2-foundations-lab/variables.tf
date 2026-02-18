#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

variable "title" {
  type        = string
  description = "Lab name"
}

variable "pod_number" {
  type        = number
  description = "Pod number"
}

variable "ip_prefix" {
  type        = string
  description = "IP prefix for the pod"
}

variable "global_ipv4_address" {
  type        = string
  description = "Global IP address for the pod"
}

variable "global_ipv4_netmask" {
  type        = string
  description = "Global IP netmask for the pod"
}

variable "global_ipv6_address" {
  type        = string
  description = "Global IPv6 address for the pod"
}

variable "global_ipv6_prefix_length" {
  type        = number
  description = "Global IPv6 prefix length for the pod"
}

variable "global_ipv6_prefix" {
  type        = string
  description = "Global IPv6 prefix for the pod"
}

variable "internet_mtu" {
  type        = number
  description = "Internet MTU for the pod"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the pod"
}

variable "bgp_ipv4_peer" {
  type        = string
  description = "BGP IPv4 peer address"
}

variable "bgp_ipv6_peer" {
  type        = string
  description = "BGP IPv6 peer address (of CML virbr1)"
}
