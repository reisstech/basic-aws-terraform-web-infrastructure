provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# VPC

resource "aws_vpc" "prod" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "production"
    }
}

# INTERNET GW

resource "aws_internet_gateway" "prod_internet_gateway" {
    vpc_id = aws_vpc.prod.id

    tags = {
        Name: "prod_internet_gw"
    }
}

# ROUTE TABLE

resource "aws_route_table" webserver_rtb {
    vpc_id = aws_vpc.prod.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod_internet_gateway.id
    }
}

resource "aws_main_route_table_association" "a" {
    vpc_id = aws_vpc.prod.id
    route_table_id = aws_route_table.webserver_rtb.id
}

# SUBNETS

resource "aws_subnet" "webserver_subnet1" {
    vpc_id = aws_vpc.prod.id
    cidr_block = "10.0.41.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "webserver_subnet2" {
    vpc_id = aws_vpc.prod.id
    cidr_block = "10.0.45.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

# KEY PAIR

resource "aws_key_pair" "web_server_key_pair" {
  key_name   = "wordpress_key_pair"
  public_key = file("wordpress_key_pair.pub")
}

resource "aws_security_group" "wordpress_sg" {
    name = "wordpress_sg"
    description = "Allow web traffic to Wordpress servers"
    vpc_id = aws_vpc.prod.id

    ingress {
        description = "Traffic to web servers on port 80"
        from_port = 0
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Traffic to web servers on port 443"
        from_port = 0
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "wordpress_security_group"
    }

}


# INSTANCES 

resource "aws_instance" "web_server_instance1" {
  ami           = "ami-0a8b4cd432b1c3063"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web_server_key_pair.key_name
  subnet_id     = aws_subnet.webserver_subnet1.id
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  user_data = "${file("script01.sh")}"

  tags = {
    Name : "Webserver1"
  }
}

resource "aws_instance" "web_server_instance2" {
  ami           = "ami-0a8b4cd432b1c3063"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web_server_key_pair.key_name
  subnet_id     = aws_subnet.webserver_subnet2.id
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  user_data = "${file("script02.sh")}"

  tags = {
    Name : "Webserver2"
    }
}

#TARGET GROUP

resource "aws_lb_target_group" "target_group_webservers" {
    name = "target-group-webservers"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.prod.id
}


# LOAD BALANCER

resource "aws_lb" "lb_webservers" {
    name = "lb-webservers"
    internal = false
    load_balancer_type = "application"
    subnets = [aws_subnet.webserver_subnet1.id, aws_subnet.webserver_subnet2.id]
    security_groups =  [ aws_security_group.alb_sg.id ]

}

output "lb_url" {
  value       = aws_lb.lb_webservers.dns_name
  description = "The LB DNS Name."

}

# LB SECURITY GROUP

resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    description = "Allow web traffic to Load Balancer"
    vpc_id = aws_vpc.prod.id

    ingress {
        description = "Traffic to ALB on port 80"
        from_port = 0
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "http_to_alb_security_group"
    }

}

# ATTACHING INSTANCES INTO TARGET GROUP

resource "aws_lb_target_group_attachment" "attach_instance1" {
  target_group_arn = aws_lb_target_group.target_group_webservers.arn
  target_id        = aws_instance.web_server_instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_instance2" {
  target_group_arn = aws_lb_target_group.target_group_webservers.arn
  target_id        = aws_instance.web_server_instance2.id
  port             = 80
}

# LB LISTENER

resource "aws_lb_listener" "webserver" {
    load_balancer_arn = aws_lb.lb_webservers.arn
    port = "80"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_group_webservers.arn
    }
}
