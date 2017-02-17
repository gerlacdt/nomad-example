variable "region" {
  default = "eu-west-1"
}

# should be larger because they are under load
variable "instance_type_master" {
  type = "string"
  default = "m4.large"
}
variable "instance_type_worker" {
  type = "string"
  default = "m4.large"
}
variable "vpc_id" {}

# user-data script worked with ubuntu 16.04
variable "ami_id" {
  type = "string"
  default = "ami-98ecb7fe"
}

variable "count_workers" {
  default = 2
}

# should be at least 3 for a consul/nomad cluster
variable "count_masters" {
  default = 3
}
variable "ssh_keyname" {}
variable "security_group_id" {}
variable "elb_subnet_ids" { default = [] }
variable "zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
# ec2-instance-profile must have permissions: ec2:DescribeInstances at least
variable "instance_profile" {}
