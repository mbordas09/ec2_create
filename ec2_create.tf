provider "aws" {
  profile    = "drip"
  region     = "us-east-1"
}

variable "key_name" {
  default = "terraform-test-key"
  }

# use tls_private_key to generate a new keypair for use with the ec2 instance
# save key to file and use "ssh -i ec2_private_key.txt" to login
#
#resource "tls_private_key" "private_key" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}

#resource "local_file" "key_file" {
#  content = "${tls_private_key.private_key.private_key_pem}"
#  filename = "ec2_private_key.txt"
#}

# Or use existing RSA key in .ssh
#
resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
#  public_key = "${tls_private_key.private_key.public_key_openssh}"
}

resource "aws_instance" "example" {
  ami           = "ami-04681a1dbd79675a5"
  instance_type = "t1.micro"
  availability_zone     = "us-east-1a"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["sg-217c8a54"]
  subnet_id = "subnet-ecd727b6"
  tags {
    Name = "drip-staging-terraform-test"
  }

# sample provisioning - create README in user homedir
  connection {
    user = "ec2-user"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "file" {
    source = "./startup"
    destination = "~/"
  }
  provisioner "remote-exec" {
    inline = [
      "cd ~/startup",
      "chmod +x run.sh",
      "./run.sh >/dev/null"
    ]
  }
}

output "ip_address" {
  value = "${aws_instance.example.public_ip}"
}

output "security_groups" {
  value = "${aws_instance.example.security_groups}"
}


