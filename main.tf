resource "aws_security_group" "sg_ucad" {
  name        = "allow_ssh_http"
  description = "Autoriser SSH et HTTP"

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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_visticot" {
  ami           = "ami-0b6c6ebed2801a5cb"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_ucad.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  tags = { Name = "EC2-visticot" }
}

output "ec2_public_ip" {
  value = aws_instance.ec2_visticot.public_ip
}