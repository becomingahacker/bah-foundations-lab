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

variable "domain_name" {
  type        = string
  description = "IP prefix for the pod"
}
