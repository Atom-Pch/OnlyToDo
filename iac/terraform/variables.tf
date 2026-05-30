variable "aws_region" {
  default     = "us-east-2"
}
variable "todo-app-secret-arn" {
  default = "arn:aws:secretsmanager:us-east-2:131912109503:secret:todo-app-secrets-14Gg8G"
}
variable "vpc_cidr" {
  default = "10.0.0.0/20"
}
variable "my_ip" {
  sensitive   = true
}
