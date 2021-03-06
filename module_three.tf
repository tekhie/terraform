##################################################################################
# VARIABLES
##################################################################################

#The AWS variables are defined in the TerraformCLOUD variables section.
# the variable value which is the PRIVATE SSH key is defined in the TerraformVariables section of TFCLOUD. These variables are added into a TFVARS
# which is read when the plan is run.  Yhe variable defined is "london_key_name", so the value is populated between the curly braces in the line below.
# The actual variable "london_key_name" is then called in the RESOURCES section of the script, which then reads the TFCLOUD variable

variable "london_key_name" {}

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
  key_name               = "MyLondonKeyPair" # this is the name of the keypair to use as seen in the AWS console.
                                             # this alows us to SSH into the instance once it has been created
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = var.london_key_name # this is the Private Key that corresponds to the  "MyLondonKeyPair" public key that resides in AWS
                                      # i have created a variable in TFCLOUD called london_key_name that contains the content
                                      # aka C:\Users\tekhi_000\OneDrive\Docker_Kubernetes\AWS\MyLondonKeyPair.ppk
  }
  
# The key_name and private_key values are used to allow the "provisioner" defined next to be able to be run on the instance.
# If you had only provided the key_namevalue, you would be able to Putty, but only becuase as part of that Putty session creation you specified the Private Key file
# By specifying both in the "connection block", you are doing the equivalent of specifying your Private Key file in order to allow the connection
# You will knwo if both the values are correct becuase if not the deploy job will get stuck on the  "install nginx" part
  
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
