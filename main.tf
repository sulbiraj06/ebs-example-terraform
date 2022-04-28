provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "private_key" {
  filename                  = "test.pem"
  content                   = tls_private_key.key.private_key_pem
  file_permission           = "0400"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "test"
  public_key = tls_private_key.key.public_key_openssh
}

#Create VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demo-vpc"
  }
}

#Create Private Subnet
/* Private subnet */
resource "aws_subnet" "tf_private_subnet" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets)

  #cidr_block              = "10.0.2.0/24"
  #availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name        = "private-subnet${format("%03d", count.index+1)}"
  }
}

#Create a private route table and edit the route and attach NAT GW, associate with private subnet

resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name        = "privare-route-table"
  }
}

/* associate with private subnet */
resource "aws_route_table_association" "tf_private_rt_association" {
    count = 2
    subnet_id      = element(aws_subnet.tf_private_subnet.*.id, count.index)
  #subnet_id      = aws_subnet.tf_private_subnet.id
  route_table_id = aws_route_table.tf_private_route_table.id
}

#Create a security group to allow port 22,80,443
resource "aws_security_group" "tf_sg_vpc" {
  name        = "allow_SSH_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.tf_vpc.id
    ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH_traffic"
  }
}

resource "aws_instance" "tf_ec2-private-instance" {
    count = 2
    ami                       = "ami-0a8b4cd432b1c3063"
    instance_type             = "t2.micro"
    subnet_id                 = element(aws_subnet.tf_private_subnet.*.id, count.index)
    vpc_security_group_ids    = [aws_security_group.tf_sg_vpc.id]
    availability_zone         = var.ec2_az[count.index]
    key_name                  = aws_key_pair.key_pair.id
    root_block_device {
        volume_size           = "${var.EC2_ROOT_VOLUME_SIZE}"
        volume_type           = "${var.EC2_ROOT_VOLUME_TYPE}"
        delete_on_termination = "${var.EC2_ROOT_VOLUME_DELETE_ON_TERMINATION}"
        tags = {
            Name = "proxy-engine-vol${format("%03d", count.index+1)}"
        }
  }

    tags = {
        Name = "proxy-engine-${format("%03d", count.index+1)}"
  }
}

resource "aws_ebs_volume" "data-vol" {
    count             = length(var.vol_az)
    availability_zone = element(aws_instance.tf_ec2-private-instance.*.availability_zone, count.index)
    size = 5
    tags = {
        Name = "data-volume"
    }

}

resource "aws_volume_attachment" "ebs-data-vol" {
    count               = length(var.vol_az)
    device_name         = "/dev/sdc"
    volume_id           = element(aws_ebs_volume.data-vol.*.id, count.index)
    instance_id         = element(aws_instance.tf_ec2-private-instance.*.id, count.index)
}
