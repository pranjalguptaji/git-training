provider "aws" {
	access_key = "AKIAIG6QXRLR6XT4YJIA"
	secret_key = "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"
	region = "us-east-1"
}

resource "aws_vpc" "terra-vpc" {
	tags = {
		Name = "terra-vpc"
	}
	cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "terra-sg" {
	name = "terra-sg"
	vpc_id = aws_vpc.terra-vpc.id
	ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
}
resource "aws_subnet" "terra-subnet" {
	tags = {
		Name = "terra-subnet"
	}
	vpc_id = aws_vpc.terra-vpc.id
	map_public_ip_on_launch = true
	cidr_block = "10.0.0.0/24"
	availability_zone = "us-east-1a"
}



resource "aws_instance" "instance_with_volume" {
        ami = "ami-01d27c68a93ba6c8f"
        instance_type = "t2.micro"
        availability_zone = "us-east-1a"
        vpc_security_group_ids = [aws_security_group.terra-sg.id]
        tags = {
                Name = "Instance-with-volume"
        }
        key_name = "third"
        subnet_id = aws_subnet.terra-subnet.id
}

resource "aws_eip" "terra-ins-eip" {
	vpc = true
	instance = aws_instance.instance_with_volume.id
}

resource "aws_ebs_volume" "data-vol" {
	size = 1
	tags = {
		Name = "data-vol"
	}
	availability_zone = "us-east-1a"
}

resource "aws_volume_attachment" "first-vol" {
        device_name = "/dev/sdc"
        volume_id = aws_ebs_volume.data-vol.id
        instance_id = aws_instance.instance_with_volume.id
}

resource "aws_internet_gateway" "terra-igw" {
	vpc_id = aws_vpc.terra-vpc.id
	tags = {
		Name = "terra-igw"
	}
}

resource "aws_elb" "terra-elb" {
	name = "terra-elb"
	internal = false
	subnets = [aws_subnet.terra-subnet.id]
	listener {
		instance_port = 8000
		instance_protocol = "http"
		lb_port = 80
		lb_protocol = "http"
	}
	health_check {
		healthy_threshold = 4
		unhealthy_threshold = 2
		timeout = 3
		target = "http:8000/"
		interval = 30
	}
	instances = [aws_instance.instance_with_volume.id]
	cross_zone_load_balancing = true
}

resource "aws_elb_attachment" "baz" {
  elb      = aws_elb.terra-elb.id
  instance = aws_instance.instance_with_volume.id
}

