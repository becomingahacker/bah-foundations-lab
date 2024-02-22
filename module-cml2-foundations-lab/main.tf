#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  v4_name_server = "172.31.0.2"    # AWS VPC DNS
  v6_name_server = "FD00:EC2::253" # AWS VPC DNS
  l0_prefix      = cidrsubnet(var.ip_prefix, 8, 1)
  l1_prefix      = cidrsubnet(var.ip_prefix, 8, 2)

  foundations_lab_notes = templatefile("${path.module}/templates/foundations-lab-notes.md.tftpl", {
    domain_name = var.domain_name,
  })

  kali_config = templatefile("${path.module}/templates/kali.cfg.tftpl", {
    domain_name    = var.domain_name,
    v4_name_server = local.v4_name_server,
    l0_prefix      = local.l0_prefix,
  })

  iosv_r1_config = templatefile("${path.module}/templates/iosv-r1.cfg.tftpl", {
    domain_name    = var.domain_name,
    v4_name_server = local.v4_name_server,
    l0_prefix      = local.l1_prefix,
    l2_prefix      = local.l0_prefix,
  })

  iosv_r2_config = templatefile("${path.module}/templates/iosv-r2.cfg.tftpl", {
    domain_name    = var.domain_name,
    v4_name_server = local.v4_name_server,
    v6_name_server = local.v6_name_server,
    ip_prefix      = var.ip_prefix,
    l0_prefix      = local.l1_prefix,
    l2_prefix      = local.l0_prefix,
    wildcard_mask  = local.wildcard_mask,
  })
}

resource "cml2_lab" "foundations_lab" {
  title       = var.title
  description = "Becoming a Hacker Foundations"
  notes       = local.foundations_lab_notes
}

resource "cml2_node" "kali" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "kali"
  nodedefinition = "kali-linux"
  ram            = 4096
  x              = 80
  y              = 120
  tags           = ["host"]
  configuration  = local.kali_config
}

resource "cml2_node" "iosv-r1" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "iosv-r1"
  nodedefinition = "iosv"
  ram            = 768
  x              = 280
  y              = 120
  tags           = ["router"]
  configuration  = local.iosv_r1_config
}

resource "cml2_node" "iosv-r2" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "iosv-r2"
  nodedefinition = "iosv"
  ram            = 768
  x              = 480
  y              = 120
  tags           = ["router"]
  configuration  = local.iosv_r2_config
}

resource "cml2_node" "ext-conn-0" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "Internet"
  nodedefinition = "external_connector"
  ram            = null
  x              = 680
  y              = 120
  tags           = ["external_connector"]
  configuration  = "NAT"
}

resource "cml2_link" "l0" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.kali.id
  node_b = cml2_node.iosv-r1.id
  slot_a = 0
  slot_b = 2
}

resource "cml2_link" "l1" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r1.id
  node_b = cml2_node.iosv-r2.id
  slot_a = 0
  slot_b = 0
}

resource "cml2_link" "l2" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r1.id
  node_b = cml2_node.iosv-r2.id
  slot_a = 1
  slot_b = 1
}

resource "cml2_link" "l3" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r2.id
  node_b = cml2_node.ext-conn-0.id
  slot_a = 2
  slot_b = 0
}

resource "cml2_lifecycle" "top" {
  lab_id = cml2_lab.foundations_lab.id

  # the elements list has the dependencies
  elements = [
    cml2_node.kali.id,
    cml2_node.iosv-r1.id,
    cml2_node.iosv-r2.id,
    cml2_node.ext-conn-0.id,
    cml2_link.l0.id,
    cml2_link.l1.id,
    cml2_link.l2.id,
    cml2_link.l3.id,
  ]

  staging = {
    stages          = ["external_connector", "router", "host"]
    start_remaining = true
  }

  state = "DEFINED_ON_CORE"

  lifecycle {
    ignore_changes = [
      state
    ]
  }
}
