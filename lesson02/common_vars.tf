variable "aws_region" {
  default = "us-west-2"
}

variable "metadata" {
  default = {
    appname    = "sample-app"
    appversion = "latest"
  }
}

variable "env" {
  description = "string for the enviroment, allowed values develop, uat, prod"
  default     = "develop"
}

variable "domain" {
  default     = "limalymon.click"
  description = "The domain name to use"
  type        = string
}

variable "tags" {
  type = map(string)

  default = {
    Name     = "sample-app"
    owner    = "devops@wizeline.com"
    bu       = "app"
    product  = "manager"
    preserve = "true"
    appid    = "sample-app-webapp"
  }
}

data "aws_caller_identity" "current" {
}
