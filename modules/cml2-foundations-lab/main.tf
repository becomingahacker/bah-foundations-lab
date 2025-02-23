#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  #v4_name_server = "169.254.169.254" # GCP DNS
  v4_name_server = "10.1.1.5" # Local metasploitable instance
  #v6_name_server = "2620:0:ccc::2"   # OpenDNS IPv6
  v6_name_server = ""
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

  iosv_r1_config = templatefile("${path.module}/templates/ioll2-xe-sw1.cfg.tftpl", {
    domain_name    = var.domain_name,
    v4_name_server = local.v4_name_server,
    v6_name_server = local.v6_name_server,
    l0_prefix      = local.l1_prefix,
    l2_prefix      = local.l0_prefix,
  })

  iosv_r2_config = templatefile("${path.module}/templates/iosv-r1.cfg.tftpl", {
    domain_name               = var.domain_name,
    v4_name_server            = local.v4_name_server,
    v6_name_server            = local.v6_name_server,
    ip_prefix                 = var.ip_prefix,
    l0_prefix                 = local.l0_prefix,
    wildcard_mask             = local.wildcard_mask,
    internet_mtu              = var.internet_mtu,
    pod_number                = var.pod_number,
    global_ipv4_address       = var.global_ipv4_address,
    global_ipv6_prefix        = var.global_ipv6_prefix,
    global_ipv6_prefix_length = var.global_ipv6_prefix_length,
    bgp_ipv6_peer             = var.bgp_ipv6_peer,
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
  ram            = 8192
  boot_disk_size = 64
  x              = 80
  y              = 120
  tags           = ["host"]
  configuration  = local.kali_config
}

resource "cml2_node" "ioll2-xe-sw1" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "ioll2-xe-sw1"
  nodedefinition = "ioll2-xe"
  ram            = 768
  x              = 280
  y              = 120
  tags           = ["switch"]
  configuration  = local.iosv_r1_config
}

resource "cml2_node" "iosv-r1" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "iosv-r1"
  nodedefinition = "iosv"
  ram            = 768
  x              = 480
  y              = 120
  tags           = ["router"]
  configuration  = local.iosv_r2_config
}

resource "cml2_node" "metasploitable" {
  lab_id          = cml2_lab.foundations_lab.id
  label           = "metasploitable"
  nodedefinition  = "metasploitable"
  imagedefinition = "metasploitable-20250221"
  x               = 0
  y               = 200
  tags            = ["host"]
}

resource "cml2_node" "windows" {
  lab_id          = cml2_lab.foundations_lab.id
  label           = "windows"
  nodedefinition  = "windows-xp"
  imagedefinition = "windows-xp-20250222"
  x               = 120
  y               = 200
  tags            = ["host"]
}

resource "cml2_node" "ext-conn-0" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "Internet"
  nodedefinition = "external_connector"
  ram            = null
  x              = 680
  y              = 120
  tags           = ["external_connector"]
  configuration  = "virbr1"
}

resource "cml2_link" "l0" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.kali.id
  node_b = cml2_node.ioll2-xe-sw1.id
  slot_a = 0
  slot_b = 1
}

resource "cml2_link" "l1" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.ioll2-xe-sw1.id
  node_b = cml2_node.iosv-r1.id
  slot_a = 0
  slot_b = 0
}

resource "cml2_link" "l2" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r1.id
  node_b = cml2_node.ext-conn-0.id
  slot_a = 1
  slot_b = 0
}

resource "cml2_link" "l3" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.metasploitable.id
  node_b = cml2_node.ioll2-xe-sw1.id
  slot_a = 0
  slot_b = 2
}

resource "cml2_link" "l4" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.windows.id
  node_b = cml2_node.ioll2-xe-sw1.id
  slot_a = 0
  slot_b = 3
}

resource "cml2_lifecycle" "top" {
  lab_id = cml2_lab.foundations_lab.id


  staging = {
    stages          = ["external_connector", "router", "switch", "host"]
    start_remaining = true
  }

  state = "DEFINED_ON_CORE"

  lifecycle {
    ignore_changes = [
      state
    ]
  }

  depends_on = [
    cml2_node.kali,
    cml2_node.ioll2-xe-sw1,
    cml2_node.iosv-r1,
    cml2_node.ext-conn-0,
    cml2_link.l0,
    cml2_link.l1,
    cml2_link.l2,
    cml2_link.l3,
    cml2_link.l4,
  ]
}
