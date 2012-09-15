#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
    class BrightboxImageList < Knife

      include Knife::BrightboxBase

      banner "knife brightbox image list (options)"

      def run
        image_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('Status', :bold)
        ]

        connection.images.sort_by(&:name).each do |image|
          image_list << image.id.to_s
          image_list << image.name
          image_list << (image.public ? "public" : "private")
        end

        puts ui.list(image_list, :columns_across, 3)
      end
    end
  end
end
