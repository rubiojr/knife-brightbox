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
    class BrightboxZoneList < Knife

      include Knife::BrightboxBase

      banner "knife brightbox zone list (options)"

      def run
        zone_list = [
          ui.color('Handle (use as the --zone switch)', :bold),
          ui.color('ID', :bold),
        ]
        connection.zones.sort_by(&:handle).each do |zone|
          zone_list << zone.handle
          zone_list << zone.id
        end
        puts ui.list(zone_list, :columns_across, 2)
      end
    end
  end
end
