data "http" "template" {
  url = "https://example.com"

  # Optional request headers
  request_headers {
    "Accept" = "application/json"
  }
}

output "file_body" {
  value = "${data.http.template.body}"
}
