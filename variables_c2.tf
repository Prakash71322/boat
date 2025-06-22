variable "stracc_name" {
   type = string
   description = "Name of the storage account"
   default = "skpstraccvar"
}

variable "nsg_ports" {
   type = map(number)
   default = {
     22 = 100
     443 = 110
     1434 = 120
     3306 = 130
     5432 = 140
     3389 = 150
     9000 = 160
     8080 = 170
     80 = 180
     1521 = 190
   }
}

variable "ip_address_allowed" {
   type = string
   default = "10.0.1.0/24"  
}