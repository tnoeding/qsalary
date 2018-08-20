#tsn - Create the qsalary Host

resource "aws_default_vpc" "default" {
    tags {
        Name = "Default VPC"
    }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-2a"

    tags {
        Name = "Default subnet for us-west-2a"
    }
}

data "aws_security_group" "default" {
  vpc_id = "${aws_default_vpc.default.id}"
  name   = "default"
}

resource "aws_instance" "qsalary-host" {
  ami                    = "ami-f2d3638a"
  instance_type          = "${var.instance_type}"
  key_name               = "KEYPAIR"
  subnet_id              = "${aws_default_subnet.default_az1.id}"
  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]
  associate_public_ip_address = true
  user_data = "${file("userdata.sh")}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  tags {
    Name      = "qsalary-host"
  }
}

output "qsalary_public_ip" {
  value = "${aws_instance.qsalary-host.public_ip}"
}
