output "db_address" {
  value = module.rds.db_instance_address
}
output "rds_secret_arn" {
  value = module.rds.db_instance_master_user_secret_arn
}
