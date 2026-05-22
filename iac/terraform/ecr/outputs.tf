output "frontend_repo_name" {
  value = module.frontend_repo.repository_name
}
output "backend_repo_name" {
  value = module.backend_repo.repository_name
}
output "prom_repo_name" {
  value = module.prom_repo.repository_name
}
output "graf_repo_name" {
  value = module.graf_repo.repository_name
}

output "frontend_repo_url" {
  value = module.frontend_repo.repository_url
}
output "backend_repo_url" {
  value = module.backend_repo.repository_url
}
output "prom_repo_url" {
  value = module.prom_repo.repository_url
}
output "graf_repo_url" {
  value = module.graf_repo.repository_url
}
