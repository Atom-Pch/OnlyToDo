output "db_address" {
  value = module.rds.db_instance_address
}
output "ssm_rds_sg" {
  value = aws_security_group.ssm_rds_sg.id
}
output "rds_secret_arn" {
  value = module.rds.db_instance_master_user_secret_arn
}