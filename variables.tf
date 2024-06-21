#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

# Common variables

variable "cfg_file" {
  type        = string
  description = "Name of the YAML config file to use"
  default     = "config.yml"
}

variable "cfg_extra_vars" {
  type        = string
  description = "extra variable definitions, typically empty"
  default     = null
}
