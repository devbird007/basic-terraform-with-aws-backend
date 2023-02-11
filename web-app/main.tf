terraform {
    backend "s3" {
        bucket          = "devops-directive-tf-state-manny"
        key             = "web-app/terraform.tfstate"
        region          = "us-east-1"
        dynamodb_table  = "terraform-state-locking"
        encrypt         = true
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

### Instance 1 & 2 ###
resource "aws_instance" "instance-01" {
    ami             = "ami-0b5eea76982371e91"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
                        #!/bin/bash
                        echo "Hello, World 1" > index.html
                        python3 -m http.server 8080 &
                        EOF
}

resource "aws_instance" "instance-02" {
    ami             = "ami-0b5eea76982371e91"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
                        #!/bin/bash
                        echo "Hello, World 2" > index.html
                        python3 -m http.server 8080 &
                        EOF
}

### S3 Bucket, Versioning and Encryption ###
resource "aws_s3_bucket" "bucket" {
    bucket          = "devops-directive-web-app-data-manny"
    force_destroy   = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.bucket.id
    versioning_configuration {
        status = "Enabled"
    }   
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
    bucket = aws_s3_bucket.bucket.bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

### VPC and Subnet ###
data "aws_vpc" "default_vpc" {
    default = true
}

data "aws_subnets" "default_subnet" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default_vpc.id]
    }
}

### Sg and Sg rule ###
resource "aws_security_group" "instances" {
    name = "instance-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type                = "ingress"
    security_group_id   = aws_security_group.instances.id
    from_port           = 8080
    to_port             = 8080
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
}

### Lb-listener, 
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.my_load_balancer.arn
    port = 80
    protocol = "HTTP"

    # by default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code  = 404
        }
    }
}

resource "aws_lb_target_group" "instances" {
    name = "manny-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default_vpc.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_target_group_attachment" "instance_1" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id        = aws_instance.instance-01.id
    port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance-02.id
    port = 8080
}

resource "aws_lb_listener_rule" "instances" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = [ "*" ]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.instances.arn
    }
}

resource "aws_security_group" "alb" {
    name = "alb-security-group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
    type                = "egress"
    security_group_id   = aws_security_group.alb.id

    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_lb" "my_load_balancer" {
    name = "web-app-lb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default_subnet.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_db_instance" "db_instance" {
    allocated_storage = 15
    storage_type = "standard"
    engine = "postgres"
    engine_version = "12"
    instance_class = "db.t2.micro"
    db_name = "mydb"
    username = "foo"
    password = "football"
    skip_final_snapshot = true
}