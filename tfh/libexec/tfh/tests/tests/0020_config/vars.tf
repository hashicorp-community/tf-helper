variable "var_int_0020" {
  default = 42 
}

variable "var_str_0020" {
  default = "foo"
}

variable "var_list_0020" {
  default = ["one", "two"]
}

variable "var_map_0020" {
  default = {
    k1 = "v1",
    k2 = "v2"
  }
}

resource "null_resource" "n" {}
