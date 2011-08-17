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

      def run
        @name_args.each do |instance_id|
          server = connection.servers.get(instance_id)
          if server.nil?
            ui.error("Server instance #{instance_id} not found. Aborting.")
            exit 1
          end
          msg("Instance ID", server.id.to_s)
          msg("Name", server.name)
          msg("Flavor", server.flavor.name)
          msg("Image", server.image.name)

          puts "\n"
          confirm("Do you really want to delete this server")

          server.destroy

          ui.warn("Deleted server #{server.id} named #{server.name}")
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
