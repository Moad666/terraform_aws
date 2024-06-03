# allows Terraform to interact with AWS to manage and provision infrastructure resources
provider "aws" {
  region = "us-east-1"
  access_key = "*******************"
  secret_key = "****************************************************"
}

# defines an AWS EC2 instance resource
# resource type
resource "aws_instance" "ec2" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
}

# Defines an Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "app" {
  name        = "my-app"
  description = "My Elastic Beanstalk Application"
}

# Defines an IAM role for Elastic Beanstalk EC2 instances
resource "aws_iam_role" "eb_role" {
  name = "elastic_beanstalk_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com" # EC2 instances are allowed to assume this role.
        }
      }
    ]
  })
}

# Defines an IAM instance profile for Elastic Beanstalk EC2 instances
# AWS object that is used to store an IAM role
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "elastic_beanstalk_ec2_instance_profile"
  role = aws_iam_role.eb_role.name
}

# Attaches the AWSElasticBeanstalkWebTier policy to the IAM role
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_full_access" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Attaches the AWSElasticBeanstalkMulticontainerDocker policy to the IAM role
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_service" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# Defines an Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "my-app-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.14 running Python 3.8"
  wait_for_ready_timeout = "30m" # the maximum amount of time Terraform will wait for the Elastic Beanstalk environment to be in a ready state after creation

  setting {
    namespace = "aws:autoscaling:launchconfiguration" #  launch configuration settings for the auto-scaling group
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }
}

# Defines an IAM user
resource "aws_iam_user" "user" {
  name = "my-user"
}

# Attaches a policy to the IAM user
resource "aws_iam_user_policy" "user_policy" {
  name   = "user-policy"
  user   = aws_iam_user.user.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:Describe*",
          "s3:List*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

# cloud storage service designed for storing and retrieving any amount of data at any time.
# Defines an s3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-us-east-1-2024"
  # Tags are key-value pairs used for organizing and managing AWS resources
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}


#Defines the outputs that you want to retrieve after your resources are created.
output "ec2_instance_id" {
  value = aws_instance.ec2.id # Outputs the EC2 instance ID
}

output "elastic_beanstalk_app_name" {
  value = aws_elastic_beanstalk_application.app.name # Outputs the Elastic Beanstalk application name
}

output "elastic_beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.env.name # Outputs the Elastic Beanstalk environment name
}

output "iam_user_name" {
  value = aws_iam_user.user.name # Outputs the IAM user name
}

output "s3_bucket" {
    value = aws_s3_bucket.my_bucket
}
