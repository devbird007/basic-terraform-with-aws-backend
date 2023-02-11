terraform {
	################################################################################
	### Provision the backend resources in this file first with terraform-apply  ###
	### then uncomment the code block below to transfer the backend to aws-cloud ###
	### Now you can move to the main folder to provision your working resources  ###
	################################################################################
	# backend "s3" {
	# 	bucket 			= "devops-directive-tf-state-manny"
	# 	key				= "backend/terraform.tfstate"
	# 	region 			= "us-east-1"
	# 	dynamodb_table 	= "terraform-state-locking"
	# 	encrypt 		= true
	# }

	required_providers {
		aws = {
      		source 	= "hashicorp/aws"
      		version = "~> 4.0"
    	}
  	}
}

provider "aws" {
  	region = "us-east-1"
}

### Declaring my backend resources ###
resource "aws_s3_bucket" "terraform_state" {
  	bucket 			= "devops-directive-tf-state-manny"
	force_destroy 	= true
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
	bucket = aws_s3_bucket.terraform_state.id
	versioning_configuration {
		status = "Enabled"
	}
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_server_side_encryption" {
	bucket = aws_s3_bucket.terraform_state.bucket 
	
	rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}  
	}
}

resource "aws_dynamodb_table" "terraform_locks" {
	name 			= "terraform-state-locking"
	billing_mode 	= "PAY_PER_REQUEST"
	hash_key 		= "LockID"
	attribute {
		name = "LockID"
		type = "S"
	}
}