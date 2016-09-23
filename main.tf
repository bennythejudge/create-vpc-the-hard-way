variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# create a VPC - it spans the entire AZ 
resource "aws_vpc" "VPC_TEST_01" {
    cidr_block = "10.0.0.0/16"
    tags {
      Name = "VPC_TEST_01"
    }
}

# create 3 public subnets
resource "aws_subnet" "PubSub-AZ-A" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-2a"
    tags {
        Name = "PubSub-AZ-A"
    }
}
resource "aws_subnet" "PubSub-AZ-B" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-west-2b"
    tags {
        Name = "PubSub-AZ-B"
    }
}
resource "aws_subnet" "PubSub-AZ-C" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-west-2c"
    tags {
        Name = "PubSub-AZ-C"
    }
}

# create 3 private subnets
resource "aws_subnet" "PrivSub-AZ-A1" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.10.0/24"
    availability_zone = "us-west-2a"
    tags {
        Name = "PrivSub-AZ-A1"
    }
}
resource "aws_subnet" "PrivSub-AZ-B1" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.11.0/24"
    availability_zone = "us-west-2b"
    tags {
        Name = "PrivSub-AZ-B1"
    }
}
resource "aws_subnet" "PrivSub-AZ-C1" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    cidr_block = "10.0.12.0/24"
    availability_zone = "us-west-2c"
    tags {
        Name = "PrivSub-AZ-C1"
    }
}

# create internet gateway
resource "aws_internet_gateway" "IGW01" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    tags {
        Name = "IGW01"
    }
}

# image for NAT EC2
# using the default VPC (allow all inbound traffic)
resource "aws_instance" "NAT01" {
    ami = "ami-75ae8245"
    instance_type = "t2.micro"
    # here I was getting an error if the following was present
    # error: 
    # Error launching source instance: InvalidParameterCombination: 
    # The parameter groupName cannot be used with the parameter 
    # subnet
    # vpc_security_group_ids = [ "vpc-9d5c5cf9", ]
    subnet_id = "${aws_subnet.PubSub-AZ-A.id}"
    key_name = "aws-ssh-keys-oregon"
    associate_public_ip_address = true
    tags {
        Name = "NAT01"
    }
}

# route tables
# PUBLIC
resource "aws_route_table" "PubRouteTable" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.IGW01.id}"
    }
    tags {
        Name = "PubRouteTable"
    }
}

resource "aws_route_table_association" "PubRouteTablePublicSubnets1" {
    subnet_id = "${aws_subnet.PubSub-AZ-A.id}"
    route_table_id = "${aws_route_table.PubRouteTable.id}"
}

resource "aws_route_table_association" "PubRouteTablePublicSubnets2" {
    subnet_id = "${aws_subnet.PubSub-AZ-B.id}"
    route_table_id = "${aws_route_table.PubRouteTable.id}"
}

resource "aws_route_table_association" "PubRouteTablePublicSubnets3" {
    subnet_id = "${aws_subnet.PubSub-AZ-C.id}"
    route_table_id = "${aws_route_table.PubRouteTable.id}"
}

# private subnets
resource "aws_route_table" "PrivRouteTable" {
    vpc_id = "${aws_vpc.VPC_TEST_01.id}"
    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.NAT01.id}"
    }
    tags {
        Name = "PrivRouteTable"
    }
}

resource "aws_route_table_association" "PrivRouteTablePrivSubn1" {
    subnet_id = "${aws_subnet.PrivSub-AZ-A1.id}"
    route_table_id = "${aws_route_table.PrivRouteTable.id}"
}
resource "aws_route_table_association" "PrivRouteTablePrivSubn2" {
    subnet_id = "${aws_subnet.PrivSub-AZ-B1.id}"
    route_table_id = "${aws_route_table.PrivRouteTable.id}"
}
resource "aws_route_table_association" "PrivRouteTablePrivSubn3" {
    subnet_id = "${aws_subnet.PrivSub-AZ-C1.id}"
    route_table_id = "${aws_route_table.PrivRouteTable.id}"
}
