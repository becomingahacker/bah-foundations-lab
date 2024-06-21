#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

variable "description" {
  type        = string
  description = "CML2 group description"
}

variable "group_name" {
  type        = string
  description = "CML2 group name"
}

variable "member_ids" {
  type        = list(string)
  description = "CML2 users to include in group"
}

variable "lab_ids" {
  type        = list(string)
  description = "CML2 labs to include in group"
}

variable "permission" {
  type        = string
  description = "default permission for the group"
  default     = "read_write"
}
