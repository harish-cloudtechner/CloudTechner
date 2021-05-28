provider "aws" {
  shared_credentials_file= "${var.project_name}.credentials"
  region  = var.region
  profile = var.environment_name
}
resource "aws_key_pair" "ctkey" {
	key_name = "ctkey"
	public_key = file("harish.pub")
	} 
