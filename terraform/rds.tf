# RDS Security Group
resource "aws_security_group" "rds" {
  name   = "t-9-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]  # Allow ECS SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet group
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "siva-t-9-rds-subnet"
  subnet_ids = data.aws_subnets.default.ids
}

# RDS MySQL
resource "aws_db_instance" "strapi" {
  identifier              = "t-9-strapi-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "strapi"
  username                = "admin"
  password                = "StrapiPassword123!"
  skip_final_snapshot     = true
  publicly_accessible     = true

  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.name
}
