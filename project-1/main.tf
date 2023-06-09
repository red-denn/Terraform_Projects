terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

}

provider "aws" {
  region = "us-east-1"
}



#Start Here:
#1. Create VPC

resource "aws_vpc" "project1-vpc" {
  cidr_block = var.vpc_cidr #used variable. Look for the value in the variable file

  tags = {
    Name = "Project1-VPC"
  }
}

#2. Create Internet Gateway

resource "aws_internet_gateway" "project1-gw" {
  vpc_id = aws_vpc.project1-vpc.id

  tags = {
    Name = "Project1-IG"
  }
}

#3. Create Custom Route Table

resource "aws_route_table" "project1-rt" {
  vpc_id = aws_vpc.project1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project1-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.project1-gw.id
  }

  tags = {
    Name = "Project1-RT"
  }
}

#4. Create Subnet

resource "aws_subnet" "project1-prod-subnet" {
  vpc_id            = aws_vpc.project1-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Project1-Prod-Subnet"
  }
}

#5. Associate Subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.project1-prod-subnet.id
  route_table_id = aws_route_table.project1-rt.id
}

#6. Create Security Group to allow ports like [22,80,443]

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web Inboundtraffic"
  vpc_id      = aws_vpc.project1-vpc.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_Web"
  }
}

#7. Create Network interface with an IP in the subnet that was created in step 4 (PRIVATE IP)

resource "aws_network_interface" "project1-web-server-nic" {
  subnet_id       = aws_subnet.project1-prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]


}

#8. Assign an elastic IP to the network interface created in step 7 (PUBLIC IP)

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.project1-web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.project1-gw] #this will reference the IG we created on the TOP. No [.id] since we want to whole object not just only the id
}


#9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "project1-web-server" {
  ami                  = "ami-0b5eea76982371e91"
  instance_type        = "t2.micro"
  availability_zone    = "us-east-1a"      #need same with subnet Azone. Need to specify to make sure amazon will not pick random Azone
  key_name             = "Pokemon_keypair" #create manually and download it to your local machine
  iam_instance_profile = "Ambulah_S3_Access"
  user_data            = file("install.sh")


  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.project1-web-server-nic.id #refrence the Nic we created on the top

  }
  tags = {
    Name = var.instace_name
  }
}



#10. Create Volume and define an EBS data source with some filter.

data "aws_ebs_volume" "ebs_volume" {
  most_recent = true

  filter {
    name   = "attachment.instance-id"
    values = ["${aws_instance.project1-web-server.id}"]
  }

}



#11. Create Snapshots using EBS

resource "aws_ebs_snapshot" "example_snapshot" {
  volume_id = data.aws_ebs_volume.ebs_volume.id

  tags = {
    Name = var.instace_name
  }
}


