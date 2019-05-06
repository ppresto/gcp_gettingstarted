data "http" "template" {
  url = "https://https://example.com"

  # Optional request headers
  request_headers {
    "Accept" = "application/json"
  }
}

data "external" "json-return" {
  program = ["/opt/chef/embedded/bin/ruby", "./json-decode.rb"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    json_str = "${data.http.template.body}"
    hostname = "${var.hostname}"
    product = "${var.product}"
  }
}

output "json_return" {
  value = "${data.external.json-return.result}"
}
