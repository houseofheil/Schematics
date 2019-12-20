variable "ssh_key" {ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDl6WhvwmTZmiaAfW1sV2JtSwH8BU9eDbUC3VM4UF6jy1K0IaC2ejXD53FS6YCULO9VQYnKCjNy7voGRpoSikCb4C1v7mERz+0wmEF6URLx/vclKVbeGTN6K3X71AZ+hKN7Y6/AdMlSbYeCe+acrQX8fWfWZS0rVcWMT/zM+lJb0Nc1gkumf9F32NTwYPQGW1EKTc01izQXf7qYh0eOKxGTZYMzHL7YTVr/K7jDVOR7q1Yx0p4LEf86c6NDuCYkrOIwnE4bEUHJAkUbITkzGl3zSMR+xoVT3GF2lsWoBAVH1Ya+n6OADtVVOVup7Y1KG0FCS4pnyt3AJf2LqUdzwqi03taE+0vggl0/Zz58GN7sMTyuPvqCJA9mM3AZNkXuR7tw0RRZ8PbtHkEH1tXRDWQkEgffZfD5gbu3c+niyUPbUiHmgYIoBl3LHU4JmqsWP6Kd04VYad3TXNDzdQ2B1jED46CChNiMeBMp/QSUAcRFuB7ohj+o+T+DP6tzg8V4yBMCnjBW43b5XETl4T5HIcvvxv5ocsfPayc5o+uPecrbYS1DcZJZ7waU7DOWUWu7IGZdjDhWUBeMVtpeBn1Bkbm9eMWBpSran5GnIuBNtPs45iWK1Ys8JxmBnsGjD44vdqraSQk+zqntvt0mGaqT0vFl3Fex3qVcPAQB1N129p2Z+Q== heil@us.ibm.com}

provider "ibm" {
  generation = 1
}

locals {
  BASENAME = "schematics" 
  ZONE     = "us-south-1"
}

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}

resource ibm_is_security_group "sg1" {
  name = "${local.BASENAME}-sg1"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_subnet "subnet1" {
  name = "${local.BASENAME}-subnet1"
  vpc  = "${ibm_is_vpc.vpc.id}"
  zone = "${local.ZONE}"
  total_ipv4_address_count = 256
}

data ibm_is_image "ubuntu" {
  name = "ubuntu-18.04-amd64"
}

data ibm_is_ssh_key "ssh_key_id" {
  name = "${var.ssh_key}"
}

data ibm_resource_group "group" {
  name = "default"
}

resource ibm_is_instance "vsi1" {
  name    = "${local.BASENAME}-vsi1"
  resource_group = "${data.ibm_resource_group.group.id}"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key_id.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "cc1-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet1.id}"
    security_groups = ["${ibm_is_security_group.sg1.id}"]
  }
}

resource ibm_is_floating_ip "fip1" {
  name   = "${local.BASENAME}-fip1"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}

