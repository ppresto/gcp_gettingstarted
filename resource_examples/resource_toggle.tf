variable “create_s3_object” {
 description = “Whether or not to create the S3 object”
 value = “true”
}

output “s3_object_created” {
 value = ${var.create_s3_object == “true” ? “S3 object created” : “S3 object not created”}
}

resource “aws_s3_bucket_object” “some_s3_objct” {
 count                 = “${var.create_s3_object == “true” ? 1 : 0}”
 bucket                 = “${aws_s3_bucket.bucket.id}”
 key                    = “some_s3_object_path/some_s3_object”
 content                = “This is an S3 object”
 server_side_encryption = “AES256”
}

# ---- create toggles.auto.tfvars file for all inputs -----
# create_s3_object = false
