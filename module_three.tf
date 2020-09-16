##################################################################################
# VARIABLES
##################################################################################

#The AWS variables are defined in the TerraformCLOUD variables section.
# the variable value which is the SSH key is defined in the TerraformVariables section of TFCLOUD. These variables are added into a TFVARS
# which is read when the plan is run.  Yhe variable defined is "london_key_name", so the value is populated between the curly braces.
# The actual variable "london_key_name" is then called in the RESOURCES section of the script

# variable "london_key_name" {}

##################################################################################
# PROVIDERS
##################################################################################

#The AWS provider is built into TerraformCLOUD so does not need downloading like if running from local PC

##################################################################################
# DATA
##################################################################################

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


##################################################################################
# RESOURCES
##################################################################################

#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow_ssh" {
  name        = "nginx_demo"
  description = "Allow ports for nginx demo"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  # key_name               = var.MyLondonKeyName
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    #private_key = var.london_key_name

  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start"
    ]
  }
}

##################################################################################
# OUTPUT
##################################################################################

output "aws_instance_public_dns" {
  value = aws_instance.nginx.public_dns
}
