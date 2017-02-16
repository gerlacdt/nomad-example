variable "region" {
  default = "eu-west-1"
}
variable "instance_type_master" {}
variable "instance_type_worker" {}
variable "vpc_id" {}
variable "ami_id" {}
variable "count_workers" {}
variable "count_masters" {}
variable "ssh_keyname" {}
variable "security_group_id" {}
variable "elb_subnet_ids" { default = [] }
variable "zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
variable "instance_profile" {}
