Step 0 :
	- AWS access key configured (aws configure) :
		
	- Terraform installed (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

	- Ansible installed

	- SSH key pair created in AWS

Step 1 : Project structure

	- Create this structure :

		terraform-ansible-project/
		│
		├── terraform/
		│   	├── main.tf
		│   	├── variables.tf
		│   	├── outputs.tf
		│  	└── terraform.tfvars
		│
		└── ansible/
   			├── inventory
    			└── playbook.yml
Step 2 : Terraform code 

	- In : variables.tf Define:

		- region

		- instance_type

		- key_name

	- In : main.tf you must create:

		- Provider block

		- Security Group (aws_security_group : allow 22 and 80)

		- EC2 instance(aws_instance)

	- Outputs.tf :
		
		- Public_Ip
		-
	- terraform.tfvars :
		
		region = "eu-west-3"
		instance_type = "t3.micro"
		key_name = "your-key-name"






















**The professional solution → Remote Backend**

Instead of storing `tfstate` locally, you store it in **AWS S3 + DynamoDB**:
```
Your Machine → terraform apply → state saved in S3 bucket
                                        ↕
                              DynamoDB locks the state
                              (prevents two people applying at same time)
