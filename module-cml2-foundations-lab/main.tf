#
# This file is part of Cisco Modeling Labs
# Copyright (c) 2019-2023, Cisco Systems, Inc.
# All rights reserved.
#

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
    <h2><li><a href="../training/" target="_blank">Lab Modules</a></h2> (Hold down Command or Control and click to open in a new tab)
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
  configuration = <<-EOT
    hostname iosv-r1
    no service config
    ip domain name becomingahacker.com
    ip name-server 172.31.0.2
    interface GigabitEthernet0/0
      description iosv-r2 Gi0/0
      ip address 10.0.0.1 255.255.255.0
    interface GigabitEthernet0/1
      description iosv-r1 Gi0/1
    ip route 0.0.0.0 0.0.0.0 10.0.0.2
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
  configuration = <<-EOT
    hostname iosv-r2
    ip domain name becomingahacker.com
    ip name-server 172.31.0.2
    ip name-server FD00:EC2::253
    ip cef
    ipv6 unicast-routing
    ipv6 cef
    interface GigabitEthernet0/0
      description iosv-r1 Gi0/0
      ip address 10.0.0.2 255.255.255.0
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
       permit ip 10.0.0.0 0.0.0.255 any
    ip nat inside source list NAT interface GigabitEthernet0/2 overload
    no banner exec
    no banner login
    no banner motd
    end
  EOT
}

resource "cml2_node" "ext-conn-0" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "ext-conn-0"
  nodedefinition = "external_connector"
  ram            = null
  x              = 440
  y              = 120
  configuration = "NAT"
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
