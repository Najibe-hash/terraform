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

resource "aws_s3_bucket" "ucad_bucket" {
  bucket = "S3-Visticot"
}


resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.ucad_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.ucad_bucket.id
  index_document {
    suffix = "index.html"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "ucad_lifecycle" {
  bucket = aws_s3_bucket.ucad_bucket.id

  rule {
    id     = "archive_and_delete_rule"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }
}


resource "aws_s3_object" "file_txt" {
  bucket  = aws_s3_bucket.ucad_bucket.id
  key     = "devoir.txt"
  content = "Ceci est le fichier texte pour le devoir Master 2 informatique UCAD et appartient à Visticot Najibe."
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.ucad_bucket.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}


resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.ucad_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  depends_on = [aws_s3_bucket_public_access_block.allow_public]
  bucket     = aws_s3_bucket.ucad_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.ucad_bucket.arn}/*"
      },
    ]
  })
}