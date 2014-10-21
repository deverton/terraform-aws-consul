##
# Consul cluster setup
##

resource "aws_security_group" "consul" {
    name = "consul"
    description = "Consul internal traffic + maintenance."
    vpc_id = "${aws_vpc.test.id}"

    ingress {
        from_port = 53
        to_port = 53
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 53
        to_port = 53
        protocol = "udp"
        self = true
    }
    ingress {
        from_port = 8300
        to_port = 8302
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 8301
        to_port = 8302
        protocol = "udp"
        self = true
    }
    ingress {
        from_port = 8400
        to_port = 8400
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        self = true
    }
}

resource "aws_instance" "consul" {
    depends_on = [ "aws_instance.bastion" ]
    connection {
        user = "ec2-user"
        key_file = "${var.key_path}"
    }
    ami = "${lookup(var.amazon_amis, var.region)}"
    instance_type = "t2.micro"
    count = 3
    key_name = "${var.key_name}"
    security_groups = [
        "${aws_security_group.allow_bastion.id}",
        "${aws_security_group.consul.id}"
    ]
    subnet_id = "${aws_subnet.private.id}"
    private_ip = "10.0.1.1${count.index}"
    tags = {
        Name = "consul${count.index}"
        subnet = "private"
        role = "dns"
        environment = "test"
    }
    user_data = "${file(\"files/consul/install-server.sh\")}"
}

