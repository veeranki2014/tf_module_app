resource "null_resource" "test" {
  triggers = {
    anka = timestamp()
  }

  provisioner "local-exec" {
    command = " echo Hello World - Env= ${var.env} "
  }
}