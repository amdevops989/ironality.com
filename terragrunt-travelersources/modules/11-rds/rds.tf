#########################
# Security Group
#########################
resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = var.vpc_id # your VPC

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] # restrict to your VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################
# Parameter Group for logical replication
#########################
resource "aws_db_parameter_group" "postgres_params" {
  name        = "postgres-costeffective-v2"
  family      = "postgres15"
  description = "Parameter group for cost effective RDS with logical replication"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_connections"
    value        = "50"
    # apply_method = "immediate"
  }
}


#########################
# RDS PostgreSQL in private subnets
#########################
resource "aws_db_subnet_group" "postgres_subnets" {
  name       = "postgres-subnet-group"
  subnet_ids = var.private_subnets  # your private subnet IDs
  description = "Subnets for RDS PostgreSQL"
}
#########################
# RDS PostgreSQL
#########################
resource "aws_db_instance" "postgres" {
  identifier             = "cost-effective-postgres"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted      = true
  username               = "postgres"
  password               = "postgres" # secure in Secrets Manager for prod
  db_name                = "mv100db"
  backup_retention_period = 0  ## should be 1 else replicas will fail
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  deletion_protection    = false
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnets.name
  parameter_group_name   = aws_db_parameter_group.postgres_params.name

  tags = {
    Environment = var.env
    Project     = "CostEffectivePostgres"
  }
}

#########################
# Run SQL initialization with retries
# Requires `psql` client installed
#########################
resource "null_resource" "init_db" {
  depends_on = [aws_db_instance.postgres]

  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
export PGPASSWORD='postgres'
HOST="${aws_db_instance.postgres.address}"
PORT=5432
USER="postgres"
DB="postgres"
SQL_FILE="./init-db.sql" 

# Wait for RDS to be available
echo "Waiting for RDS instance to be ready..."
for i in {1..30}; do
    pg_isready -h $HOST -p $PORT -U $USER && break
    echo "RDS not ready yet, waiting 10s..."
    sleep 10
done

# Run the SQL initialization
echo "Running SQL initialization..."
psql --host="$HOST" --port=$PORT --username=$USER --dbname=$DB -f $SQL_FILE

echo "SQL initialization completed."
EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
