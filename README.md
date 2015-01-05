# Terraform AWS Test Environment

This is an experimentthat creates a test environment subset in a VPC in AWS. The default region is ```us-west-2```. It creates three subnets DMZ, Public, Private and installs a bastion box in DMZ to allow access to the other subnets. It also installs a Consul cluster which is used as the DNS server for hosts within the VPC.

## Prerequisites

You must have an AWS account to use these instructions. Once you have one, create an IAM user called ```terraform``` and save the access and secret keys that are given to you.  Then ensure that the ```terraform``` user has the "Amazon EC2 Full Access" policy template applied either a via group or role.

Now install the ```awscli``` command line tools. On OS X that can be done by ```brew install awscli```. Once the tools are installed run

```sh
$ aws configure
AWS Access Key ID [None]: <YOUR ACCESS KEY>
AWS Secret Access Key [None]: <YOUR SECRET KEY>
Default region name [None]: us-west-2
Default output format [None]:
```

When prompted for the access and secret keys, enter the ones you saved earlier. Set the default region to ```us-west-2``` and the output format can be left as default. 

Now install terraform (0.3.1 or later) by downloading the right binaries from http://www.terraform.io/downloads.html and extracting them on to your path somewhere. You can test things work by running ```terraform``` on the command line.

To get started first create an empty directory to act as the working directory, change to it, and then initialise terraform with this module:

```sh
$ terraform init https://github.com/deverton/terraform-aws-consul.git
```

You will now need to create a file in this directory called ```terraform.tfvars``` with contents like this:

```
access_key = "YOUR ACCESS KEY"
secret_key = "YOUR SECRET KEY"
allowed_network = "YOUR NETWORK CIDR"
```

Populate the above values with your AWS IAM keys you saved earlier and the CIDR of the network you want to allow access to the bastion host.

To allow SSH access to the test VPC you must import your public key in to EC2.

```sh
$ aws ec2 import-key-pair --public-key-material file://~/.ssh/id_rsa.pub --key-name terraform
```

You should then be able to apply the module. Note that this may cost you money (though not much at the moment).

```sh
$ terraform apply
```

Once you have an environment running you can SSH to the bastion server as follows. The -A argument enables agent forwarding which will allow you to SSH from the bastion host to other hosts without a password.

```sh
$ ssh -A ec2-user@$(terraform output bastion)
```

Note that it will take some time for the instances to actually start up and spawn the SSH service so you will get connection refused for a while, up to five minutes. Once you've got on to the box, you can prove that Consul is being used for DNS by running dig. Your output should look something like this:

```sh
[ec2-user@ip-10-0-201-28 ~]$ dig consul.service.consul +noall +answer SRV

; <<>> DiG 9.8.2rc1-RedHat-9.8.2-0.23.rc1.32.amzn1 <<>> consul.service.consul +noall +answer SRV
;; global options: +cmd
consul.service.consul.  0   IN  SRV 1 1 8300 ip-10-0-1-11.node.dc1.consul.
consul.service.consul.  0   IN  SRV 1 1 8300 ip-10-0-1-12.node.dc1.consul.
consul.service.consul.  0   IN  SRV 1 1 8300 ip-10-0-1-10.node.dc1.consul.
```

To destroy the environment do this:

```sh
$ terraform plan -destroy -out=destroy.tfplan
$ terraform apply destroy.tfplan
```

Due to a bug in terraform you can't just used ```terraform destroy``` and you may find you'll need to repeat the ```apply``` command as well.

## Notes

To provision the non-public facing (i.e. everything other than the bastion host) you have to use cloud-init. See the consul.tf file for an example.

