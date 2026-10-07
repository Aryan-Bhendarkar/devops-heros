# A data source only READS existing information, it creates nothing.
# Here: the newest Amazon Linux 2023 image published by Amazon.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id        # implicit dependency: needs the subnet first
  vpc_security_group_ids = [aws_security_group.web.id] # implicit dependency: needs the security group first

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>Session 19: this server was created by Terraform</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOT

  # Explicit dependency: nothing in this resource references the route table association,
  # but the instance needs internet access at boot (to install httpd), so the route must exist first.
  depends_on = [aws_route_table_association.public]

  metadata_options {
    http_tokens = "required" # require IMDSv2
  }

  tags = {
    Name      = "session19-web-server"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}
