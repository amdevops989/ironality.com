output "db_instance_id" {
  value = aws_db_instance.postgres.id
}

output "db_instance_arn" {
  value = aws_db_instance.postgres.arn
}

output "db_instance_identifier" {
  value = aws_db_instance.postgres.identifier
}