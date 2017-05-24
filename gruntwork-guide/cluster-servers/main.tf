provider "aws" {
  region = "us-west-2"
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-efd0428f"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.instance.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, world" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-gruntwork-example-autoscaling"

    ingress {
      from_port = "${var.server_port}"
      to_port = "${var.server_port}"
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
      create_before_destroy = true
    }
}
data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
    launch_configuration = "${aws_launch_configuration.example.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]

    min_size = 2
    max_size = 10

    load_balancers = ["${aws_elb.example.name}"]
    health_check_type = "ELB"

    tag {
      key = "name"
      value = "terraform-gruntwork-example-asg"
      propagate_at_launch = true
    }
}

resource "aws_elb" "example" {
    name = "terraform-gruntwork-elb"
    security_groups = ["${aws_security_group.elb.id}"]
    availability_zones = ["${data.aws_availability_zones.all.names}"]

    listener {
      instance_port = "${var.server_port}"
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:${var.server_port}/"
      interval = 30
    }
}

resource "aws_security_group" "elb" {
    name = "terraform-gruntwork-elb-sg"

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}