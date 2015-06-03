#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/brightbox_base'

class Chef
  class Knife
    class BrightboxServerDelete < Knife

      include Knife::BrightboxBase

      banner "knife brightbox server delete SERVER_ID [SERVER_ID] (options)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the EC2 node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def wait_for_release
        yield
        true
      rescue Excon::Errors::Forbidden
        sleep 1
        false
      end

      def run
        @name_args.each do |instance_id|
          server = connection.servers.get(instance_id)

          if server.nil?
            ui.error("Server instance #{instance_id} not found. Aborting.")
            exit 1
          end
          msg("Instance ID", server.id.to_s)
          msg("Name", server.name)
          msg("Flavor", server.flavor.name) if server.flavor
          msg("Image", server.image.name) if server.image
          msg("Public IP Address", server.public_ip_address)

          puts "\n"
          confirm("Do you really want to delete this server")

          server.destroy

          ui.warn("Deleted server #{server.id} named #{server.name}")

          if config[:purge]
            thing_to_delete = config[:chef_node_name] || server.name
            destroy_item(Chef::Node, thing_to_delete, "node")
            destroy_item(Chef::ApiClient, thing_to_delete, "client")

            server.cloud_ips.each do |cid|
              cid = connection.cloud_ips.get(cid["id"])
              print "#{ui.color("WARNING:", :yellow)} Deleted cloud ip (#{cid.id})"
              print(".") until wait_for_release { cid.destroy; puts("done!") }
            end
          else
            ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
          end
        end
      end

      def msg(label, value)
        if value && !value.empty?
          puts "#{ui.color(label, :cyan)}: #{value}"
        end
      end
    end
  end
end
