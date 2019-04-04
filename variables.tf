# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "name"              { default = "dxiao-sandbox-test" }
variable "ssh_key_name"      { default = "your-key-pair-name-here"}
variable "region"            { default = "us-east-1"}

variable "project_tags" {
  type    = "map"
    default = {
    Owner = "davxiao"
    Environment = "Non-production"
    Billing = "Sandbox"
  }
}
variable "ami_id"     { default = "ami-02da3a138888ced85"}#Amazon Linux 2
#variable "ami_id"     { default = "ami-011b3ccf1bd6db744"}#RHEL 7.6

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_id" { default = "your-vpc-id-here" }

variable "subnet_ids" {
  type    = "list"
  default = ["your-subnet-id-1", "your-subnet-id-2" ]
}

variable "ec2_pg" { default = "dxiao-test-cluster-pg" } #placement group

variable "alb_name"           { default = ""}  
variable "alb_tg_name"        { default = "" }
