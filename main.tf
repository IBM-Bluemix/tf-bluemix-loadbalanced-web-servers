##############################################################################
# IBM Cloud Provider
# Provider details available at
# http://ibmcloudterraformdocs.chriskelner.com/docs/providers/ibmcloud/index.html
##############################################################################
# See the README for details on ways to supply these values
provider "ibmcloud" {
  ibmid                    = "${var.ibmid}"
  ibmid_password           = "${var.ibmidpw}"
  softlayer_account_number = "${var.slaccountnum}"
}

##############################################################################
# IBM VLANs
# http://ibmcloudterraformdocs.chriskelner.com/docs/providers/ibmcloud/r/infra_vlan.html
##############################################################################
resource "ibmcloud_infra_vlan" "public_vlan" {
   name = "${var.public_vlan_name}"
   datacenter = "${var.datacenter}"
   type = "PUBLIC"
   subnet_size = "${var.subnet_size}"
}

resource "ibmcloud_infra_vlan" "private_vlan" {
   name = "${var.private_vlan_name}"
   datacenter = "${var.datacenter}"
   # private ONLY vlan network configurations require a vyatta appliance to talk
   # to servers/services from the public network and ordering a vyatta requires
   # an upgraded SL account which most people do not have access to (also costly)
   # e.g. https://aws.amazon.com/premiumsupport/knowledge-center/public-load-balancer-private-ec2/
   type = "PRIVATE"
   subnet_size = "${var.subnet_size}"
}

##############################################################################
# IBM SSH Key: For connecting to VMs
# http://ibmcloudterraformdocs.chriskelner.com/docs/providers/ibmcloud/r/infra_ssh_key.html
##############################################################################
resource "ibmcloud_infra_ssh_key" "ssh_key" {
  label = "${var.key_label}"
  notes = "${var.key_note}"
  # Public key, so this is completely safe
  public_key = "${var.public_key}"
}

##############################################################################
# IBM Virtual Guests -- Web Resource Definition
# http://ibmcloudterraformdocs.chriskelner.com/docs/providers/ibmcloud/r/infra_virtual_guest.html
##############################################################################
resource "ibmcloud_infra_virtual_guest" "web_node" {
  # number of nodes to create, will iterate over this resource
  count                = "${var.node_count}"
  # demo hostname and domain
  hostname             = "${var.vm_domain}-${count.index+1}"
  domain               = "${var.vm_domain}"
  # the operating system to use for the VM
  os_reference_code    = "${var.web_operating_system}"
  # the datacenter to deploy the VM to
  datacenter           = "${var.datacenter}"
  public_vlan_id       = "${ibmcloud_infra_vlan.public_vlan.id}"
  private_vlan_id      = "${ibmcloud_infra_vlan.private_vlan.id}"
  private_network_only = false
  cores                = "${var.vm_cores}"
  memory               = "${var.vm_memory}"
  local_disk           = true
  ssh_key_ids = [
    "${ibmcloud_infra_ssh_key.ssh_key.id}"
  ]
  post_install_script_uri = "https://raw.githubusercontent.com/IBM-Bluemix/tf-bluemix-loadbalanced-web-servers/master/post-install.sh"
  # applys tags to the VM
  tags = "${var.vm_tags}"
}

##############################################################################
# IBM Local Load Balancer
# http://ibmcloudterraformdocs.chriskelner.com/docs/providers/ibmcloud/r/infra_lb_local.html
##############################################################################
# Core load balancer resource and service group
# This uses a module to create these resources
# https://github.com/ckelner/tf_ibmcloud_local_loadbalancer
module "loadbalancer" {
  source = "github.com/ckelner/tf_ibmcloud_local_loadbalancer?ref=v1.1"
  connections = 250
  datacenter = "${var.datacenter}"
}
# Defines a service for each node; determines the health check, load balancer weight, and ip the loadbalancer will send traffic to
resource "ibmcloud_infra_lb_local_service" "web_lb_local_service" {
  # The number of services to create, based on web node count
  count = "${var.node_count}"
  # port to serve traffic on
  port = "${var.port}"
  enabled = true
  service_group_id = "${module.loadbalancer.service_group_id}"
  # Even distribution of traffic
  weight = 1
  # Uses HTTP to as a healthcheck
  health_check_type = "HTTP"
  # Where to send traffic to
  ip_address_id = "${element(ibmcloud_infra_virtual_guest.web_node.*.ip_address_id, count.index)}"
  # For demonstration purposes; creates an explicit dependency
  depends_on = ["ibmcloud_infra_virtual_guest.web_node"]
}

##############################################################################
# Variables
##############################################################################
# Required for the IBM Cloud provider
variable ibmid {
  type = "string"
  description = "Your IBM-ID."
}
# Required for the IBM Cloud provider
variable ibmidpw {
  type = "string"
  description = "The password for your IBM-ID."
}
# Required to target the correct SL account
variable slaccountnum {
  type = "string"
  description = "Your Softlayer account number."
}
# The datacenter to deploy to
variable datacenter {
  default = "dal06"
}
variable public_vlan_name {
  description = "The name of the public VLAN that the web servers will be placed in."
  default = "demo-schematics-public-vlan"
}
variable private_vlan_name {
  description = "The name of the private VLAN that the web servers will be placed in."
  default = "demo-schematics-private-vlan"
}
variable subnet_size {
  description = "The size of the subnet for the public and private VLAN that the web servers will be placed in."
  default = 16
}
# The SSH Key to use on the Nginx virtual machines
variable public_key {
  description = "Your public SSH key material."
}
variable key_label {
  description = "A label for the SSH key that gets created."
  default = "schematics-demo-ssh-key"
}
variable key_note {
  description = "A note for the SSH key that gets created."
  default = ""
}
# The number of web nodes to deploy; You can adjust this number to create more
# virtual machines in the IBM Cloud; adjusting this number also updates the
# loadbalancer with the new node
variable node_count {
  description = "The number of web servers to create and put behind the load balancer."
  default = 2
}
# The target operating system for the web nodes
variable web_operating_system {
  default = "UBUNTU_LATEST"
}
# The port that web and the loadbalancer will serve traffic on
variable port {
  default = "80"
}
# The number of cores each web virtual guest will recieve
variable vm_cores {
  description = "The number of cores the web servers will have."
  default = 1
}
# The amount of memory each web virtual guest will recieve
variable vm_memory {
  description = "the amount of memory the web servers will have."
  default = 1024
}
variable vm_domain {
  description = "The domain name for your VMs."
  default = "schematics-example.com"
}
# Tags which will be applied to the web VMs
variable vm_tags {
  default = [
    "nginx",
    "webserver",
    "demo",
    "schematics"
  ]
}

##############################################################################
# Outputs: printed at the end of terraform apply
##############################################################################
output "vlan_id" {
  value = "${ibmcloud_infra_vlan.public_vlan.id}"
}
output "vlan_resources" {
  value = "${ibmcloud_infra_vlan.public_vlan.child_resource_count}"
}
output "vlan_subnets" {
  value = "${ibmcloud_infra_vlan.public_vlan.subnets}"
}
output "ssh_key_id" {
  value = "${ibmcloud_infra_ssh_key.ssh_key.id}"
}
output "node_ids" {
  value = ["${ibmcloud_infra_virtual_guest.web_node.*.id}"]
}
output "node_ips" {
  value = ["${ibmcloud_infra_virtual_guest.web_node.*.ipv4_address_private}"]
}
output "loadbalancer_id" {
  value = "${module.loadbalancer.loadbalancer_id}"
}
output "loadbalancer_address" {
  value = "${module.loadbalancer.loadbalancer_address}"
}
