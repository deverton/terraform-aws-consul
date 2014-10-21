##
# Create a bastion host to allow SSH in to the test network.
# Connections are only allowed from Wotif networks.
# This box also acts as a NAT for the private network
##

resource "aws_security_group" "bastion" {
    name = "bastion"
    description = "Allow SSH from Wotif, Consul, and NAT internal traffic"
    vpc_id = "${aws_vpc.test.id}"

    # SSH
    ingress = {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${var.allowed_network}" ]
        self = false
    }

    # HAProxy Stats
    ingress = {
        from_port = 1936
        to_port = 1936
        protocol = "tcp"
        cidr_blocks = [ "${var.allowed_network}" ]
        self = false
    }

    # Consul
    ingress = {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        cidr_blocks = [ "${var.allowed_network}" ]
        self = false
    }

    # NAT
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = [
            "${aws_subnet.public.cidr_block}",
            "${aws_subnet.private.cidr_block}"
        ]
        self = false
    }
}

resource "aws_security_group" "allow_bastion" {
    name = "allow_bastion_ssh"
    description = "Allow access from bastion host"
    vpc_id = "${aws_vpc.test.id}"
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
        self = false
    }
}

resource "aws_instance" "bastion" {
    connection {
        user = "ec2-user"
        key_file = "${var.key_path}"
    }
    ami = "${lookup(var.amazon_nat_amis, var.region)}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    security_groups = [
        "${aws_security_group.bastion.id}"
    ]
    subnet_id = "${aws_subnet.dmz.id}"
    associate_public_ip_address = true
    source_dest_check = false
    user_data = "${file(\"files/bastion/cloud-config.yaml\")}"

    provisioner "file" {
        source = "files/bastion/haproxy.cfg"
        destination = "/home/ec2-user/haproxy.cfg"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /home/ec2-user/haproxy.cfg /etc/haproxy/haproxy.cfg",
            "sudo service haproxy restart"
        ]
    }

    tags = {
        Name = "bastion"
        subnet = "dmz"
        role = "bastion"
        environment = "test"
    }
}

output "bastion" {
    value = "${aws_instance.bastion.public_ip}"
}

