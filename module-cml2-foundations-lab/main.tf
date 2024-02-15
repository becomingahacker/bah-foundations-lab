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
    <img src="../training/os_files/hacker_2.png" width="15%" height="15%">
    <hr>
    <a href="../training/" target="_blank"><h1>Lab Modules</h1></a>
    </div>
  EOT
}

resource "cml2_node" "r1" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "R1"
  nodedefinition = "alpine"
  ram            = 512
  x              = 100
  y              = 130
  tags           = ["group1"]
}

resource "cml2_node" "r2" {
  lab_id         = cml2_lab.foundations_lab.id
  label          = "R2"
  nodedefinition = "alpine"
  ram            = 512
  x              = 300
  y              = 130
}

resource "cml2_link" "l0" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.r1.id
  slot_a = 3
  node_b = cml2_node.r2.id
  slot_b = 3
}

resource "cml2_link" "l1" {
  lab_id = cml2_lab.foundations_lab.id
  node_a = cml2_node.r1.id
  slot_a = 2
  node_b = cml2_node.r2.id
  slot_b = 2
}

resource "cml2_lifecycle" "top" {
  lab_id = cml2_lab.foundations_lab.id
  # the elements list has the dependencies
  elements = [
    cml2_node.r1.id,
    cml2_node.r2.id,
    cml2_link.l0.id,
    cml2_link.l1.id,
  ]
  staging = {
    stages          = ["group1"]
    start_remaining = true
  }
   state = "STOPPED"
}
