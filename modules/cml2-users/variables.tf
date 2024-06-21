#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

variable "username" {
  type        = string
  description = "User name"
}

variable "fullname" {
  type        = string
  description = "User full name"
}

variable "description" {
  type        = string
  description = "User description"
}

variable "email" {
  type        = string
  description = "User email address"
}

variable "is_admin" {
  type        = bool
  description = "If user is an admin or not"
  default     = false
}

variable "password" {
  type        = string
  description = "User password"
  default     = ""
}