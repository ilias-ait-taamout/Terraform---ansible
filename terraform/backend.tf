terraform {
  backend "s3" {
    bucket         = "tfstate-ilias-devops-2024"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "Lock-tfstate"
    encrypt        = true
  }
}
