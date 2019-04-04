

resource "aws_security_group" "ec2_sg" {
  name        = "dxiao-sandbox-test-sg"
  description = "dxiao-sandbox-test ec2 instance" # mandatory field
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.project_tags}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["1.2.3.4/32"]
    description = "home ip"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.name}-alb-sg"
  description = "sg for ${var.name}-alb" # mandatory field
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.project_tags}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["external-cidr"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["external-cidr"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  count                    = 2
  ami                      = "${var.ami_id}"
  instance_type            = "t2.micro"
  subnet_id                = "${var.subnet_ids[0]}"
  key_name                 = "${var.ssh_key_name}"
  monitoring               = false
  vpc_security_group_ids   = ["${aws_security_group.ec2_sg.id}"]
#  iam_instance_profile     = "${var.iam_instance_profile}"
  volume_tags              = "${var.volume_tags}"
  root_block_device        = [{
      volume_type = "gp2"
      volume_size = 30
      delete_on_termination = true
    }]
  associate_public_ip_address      = false
  tags = "${var.project_tags}"
  user_data = "${file("nginx.sh")}"
}


resource "aws_lb_target_group" "this" {
  name = "dxiao-sandbox-test-sg"
  port = "443"
  protocol = "HTTPS"
  vpc_id = "${var.vpc_id}"
}

resource "aws_lb_target_group_attachment" "this" {
  count = 4
  target_group_arn = "${aws_lb_target_group.this.arn}"
  target_id = "${element("${aws_instance.this.id}", count.index)}"
  port = 443
}

resource "aws_lb" "this" {
  name = "${var.alb_name}"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.alb_sg.id}"]
  subnets = ["${var.subnet_ids[0]}"]
  tags   = "${var.project_tags}"
}

resource "aws_lb_listener" "this_1" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "arn:aws:acm:us-east-1:your-aws-acc-number:certificate/blah-blah"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.arn}"
  }
}

resource "aws_lb_listener" "this_2" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
