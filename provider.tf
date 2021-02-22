provider "aws" {
  shared_credentials_file= "${var.project_name}.credential"
  region  = var.region
  profile = var.environment_name
}
