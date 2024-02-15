#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  # HACK cmm - gross!
  wildcard_mask = [
    "255.255.255.255",
    "127.255.255.255",
    "63.255.255.255",
    "31.255.255.255",
    "15.255.255.255",
    "7.255.255.255",
    "3.255.255.255",
    "1.255.255.255",
    "0.255.255.255",
    "0.127.255.255",
    "0.63.255.255",
    "0.31.255.255",
    "0.15.255.255",
    "0.7.255.255",
    "0.3.255.255",
    "0.1.255.255",
    "0.0.255.255",
    "0.0.127.255",
    "0.0.63.255",
    "0.0.31.255",
    "0.0.15.255",
    "0.0.7.255",
    "0.0.3.255",
    "0.0.1.255",
    "0.0.0.255",
    "0.0.0.127",
    "0.0.0.63",
    "0.0.0.31",
    "0.0.0.15",
    "0.0.0.7",
    "0.0.0.3",
    "0.0.0.1",
    "0.0.0.0",
  ]
  l0_prefix = cidrsubnet(var.ip_prefix, 8, 1)
}

resource "cml2_lab" "foundations_lab" {
  title       = var.title
  description = "Becoming a Hacker Foundations"
  notes       = <<-EOT
    # Becoming a Hacker Foundations - Lab Guide
    <div class="foo">
    <br>
    <img src="../training/os_files/hacker_2.png" width="15%" height="15%">
    <br>
    <hr>
    <br>
    <ul>
    <h2><li><a href="../training/" target="_blank">Lab Modules</a></h2>
    Hold down Command or Control and click to open in a new tab
    </ul>
    </div>
  EOT
}

resource "cml2_node" "iosv-r1" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "iosv-r1"
  nodedefinition = "iosv"
  ram            = 768
  x              = 80
  y              = 120
  tags           = ["group1"]
  configuration  = <<-EOT
    hostname iosv-r1
    no service config
    ip domain name ${var.domain_name}
    ip name-server 172.31.0.2
    interface GigabitEthernet0/0
      description iosv-r2 Gi0/0
      ip address ${format("%s %s", cidrhost(local.l0_prefix, 1), cidrnetmask(local.l0_prefix))} 
    interface GigabitEthernet0/1
      description iosv-r1 Gi0/1
    ip route 0.0.0.0 0.0.0.0 ${cidrhost(local.l0_prefix, 2)}
    no banner exec
    no banner login
    no banner motd
    end
  EOT
}

resource "cml2_node" "iosv-r2" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "iosv-r2"
  nodedefinition = "iosv"
  ram            = 768
  x              = 280
  y              = 120
  configuration  = <<-EOT
    hostname iosv-r2
    no service config
    ip domain name ${var.domain_name}
    ip name-server 172.31.0.2
    ip name-server FD00:EC2::253
    ip cef
    ipv6 unicast-routing
    ipv6 cef
    interface GigabitEthernet0/0
      description iosv-r1 Gi0/0
      ip address ${format("%s %s", cidrhost(local.l0_prefix, 2), cidrnetmask(local.l0_prefix))} 
      ip nat inside
    interface GigabitEthernet0/1
      description iosv-r1 Gi0/1
    interface GigabitEthernet0/2
      ip address dhcp
      ipv6 address dhcp
      ip nat outside
      ipv6 address autoconfig default
      ipv6 enable
    ip access-list extended NAT
       permit ip ${cidrhost(var.ip_prefix, 0)} ${local.wildcard_mask[16]} any
    ip nat inside source list NAT interface GigabitEthernet0/2 overload
    no banner exec
    no banner login
    no banner motd
    end
  EOT
}

resource "cml2_node" "ext-conn-0" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "Internet"
  nodedefinition = "external_connector"
  ram            = null
  x              = 440
  y              = 120
  configuration  = "NAT"
}

resource "cml2_link" "l0" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r1.id
  node_b = cml2_node.iosv-r2.id
  slot_a = 0
  slot_b = 0
}

resource "cml2_link" "l1" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.iosv-r1.id
  node_b = cml2_node.iosv-r2.id
  slot_a = 1
  slot_b = 1
}

resource "cml2_link" "l2" {
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
    cml2_node.iosv-r1.id,
    cml2_node.iosv-r2.id,
    cml2_node.ext-conn-0.id,
    cml2_link.l0.id,
    cml2_link.l1.id,
    cml2_link.l2.id,
  ]

  staging = {
    stages          = ["group1"]
    start_remaining = true
  }

  state = "DEFINED_ON_CORE"

  lifecycle {
    ignore_changes = [
      state
    ]
  }
}
