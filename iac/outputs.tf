output "app_runner_service_url" {
  value = aws_apprunner_service.golang-app.service_url
}

output "lightsail_service_url" {
  value = aws_lightsail_container_service.golang_app.url
}
