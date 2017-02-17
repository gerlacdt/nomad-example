provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "nomad-masters" {
  count = "${var.count_masters}"
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type_master}"
  key_name = "${var.ssh_keyname}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  user_data = "${file("./scripts/server-install.sh")}"
  subnet_id = "${element(var.elb_subnet_ids, 0)}"
  iam_instance_profile = "${var.instance_profile}"
  tags {
    Name = "nomad-server-dev"
  }
}

resource "aws_elb" "nomad-worker-elb" {
  name = "nomad-worker-elb"
  subnets = ["${var.elb_subnet_ids}"]
  security_groups = ["${var.security_group_id}"]
  internal = true

  listener {
    instance_port = 9999
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 9998
    instance_protocol = "http"
    lb_port = 9998
    lb_protocol = "http"
  }

  listener {
    instance_port = 8500
    instance_protocol = "http"
    lb_port = 8500
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:9998/health"
    interval = 15
  }

  tags {
    Name = "danger-nomad-elb"
  }
}

resource "aws_autoscaling_group" "nomad-worker-asg" {
  depends_on = ["aws_instance.nomad-masters"]
  availability_zones = ["${var.zones}"]
  name = "danger-nomad-worker-asg"
  max_size = "${var.count_workers}"
  min_size = "${var.count_workers}"
  desired_capacity = "${var.count_workers}"
  health_check_grace_period = 300
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.nomad-worker-lc.name}"
  load_balancers = ["${aws_elb.nomad-worker-elb.name}"]
  vpc_zone_identifier = ["${var.elb_subnet_ids}"]

  tag {
    key = "Name"
    value = "nomad-worker-dev"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nomad-worker-lc" {
  name = "danger-nomad-worker-lc"
  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type_worker}"
  security_groups = ["${var.security_group_id}"]
  user_data = "${file("./scripts/client-install.sh")}"
  key_name = "${var.ssh_keyname}"
  iam_instance_profile = "${var.instance_profile}"
  root_block_device = {
    volume_size = 30
  }
}
