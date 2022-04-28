variable "private_subnets" {
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "ec2_az" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "EC2_ROOT_VOLUME_SIZE" {
  type    = string
  default = "8"
  description = "The volume size for the root volume in GiB"
}
variable "EC2_ROOT_VOLUME_TYPE" {
  type    = string
  default = "gp2"
  description = "The type of data storage: standard, gp2, io1"
}
variable "EC2_ROOT_VOLUME_DELETE_ON_TERMINATION" {
  default = true
  description = "Delete the root volume on instance termination."
}
variable "vol_az" {
  default = ["us-east-1a", "us-east-1b"]
}
