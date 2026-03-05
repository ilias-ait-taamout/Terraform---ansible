
resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = "tfstate-ilias-devops-2024"
  tags = {
    Name        = "tfstate_bucket"
    Environment = "Production"
  }
}

resource "aws_dynamodb_table" "Lock-tfstate" {
  name         = "Lock-tfstate"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
