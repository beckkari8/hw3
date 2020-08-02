terraform {
    backend "s3" {
        bucket = "jenkins-instance-beck"
        key = "jenkins/us-east-1/hw3/infrastructure.tfstate"
        region = "us-east-1"
    }
}