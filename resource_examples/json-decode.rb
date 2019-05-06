#!/opt/chef/embedded/bin/ruby
require 'json'
require 'base64'

        def get_tags(hostname, product, taxonomy_details)
                tags = Array.new
                host_regex_array = Array.new
                host_mid = nil
                host_number = hostname.scan(/\d+/).last
                host_regex_array = taxonomy_details["tags"].keys
                host_regex_array.each do |my|
                        if (Regexp.new(my).match(hostname))
                                host_mid = my
                                break
                        end
                end
                if host_mid != nil
                        if (taxonomy_details["tags"][host_mid].keys.include? "tag2")
                                if (host_number.to_i % 2 == 0)
                                        taxonomy_details["tags"][host_mid]["tag2"].each do |tag|
                                                if not (tag.include? '<')
                                                        tags << tag
                                                end
                                        end
                                else
                                        taxonomy_details["tags"][host_mid]["tag1"].each do |tag|
                                                if not (tag.include? '<')
                                                        tags << tag
                                                end
                                        end
                                end
                        else
                                taxonomy_details["tags"][host_mid]["tag1"].each do |tag|
                                        if not (tag.include? '<')
                                                tags << tag
                                        end
                                end
                        end
                        if (product == 'lms')
                                if(hostname=~/(^(qa|me|mc|ac|mp|pp|mu|ac|ap|ml|my|cq|ma|pq|pc|sc|ps|dev|dc)[0-9]+(lp|lqap|lqm|lc|lw|devlp)[0-9]+)/i)then tags << $1; end
                        end
                        return tags.map(&:upcase).join(',')
                else
                        return "[ERROR] Tags are missing for the hostname = #{hostname}"
                end
        end


x = STDIN.read
input = JSON.parse(x)
hostname = input["hostname"]
product = input["product"]
parsed_json =  JSON.parse(input["json_str"])
actual_content = JSON.parse(Base64.decode64(parsed_json["content"]))
tags = get_tags(hostname, product, actual_content)
final_tags = Hash.new
final_tags["tags"] = tags
puts final_tags.to_json
