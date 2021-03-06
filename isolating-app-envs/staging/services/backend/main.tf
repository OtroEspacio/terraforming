module "backend" {
  source = "../../../../modules/backend-app"

  # This variables are defined in the backend module vars.tf file
  server_port = 8080
  aws_region = "us-west-2"
  environment = "staging"
  instance_type = "t2.micro"
}
