variable "instace_name" {
    description = "Name assigned to every instance made"
    type = string
    default = "Project3_Instance"
}

#VPC
variable "vpc_cidr" {
    description = "VPC Cidr"
    #type = string
    default = "10.0.0.0/16"
}

