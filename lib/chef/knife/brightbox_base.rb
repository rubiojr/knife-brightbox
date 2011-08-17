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

require 'chef/knife'

class Chef
  class Knife
    module BrightboxBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'net/ssh/multi'
            require 'readline'
            require 'chef/json_compat'
          end

          option :brightbox_secret,
            :short => "-K KEY",
            :long => "--brightbox-api-key KEY",
            :description => "Your brightbox API key",
            :proc => Proc.new { |key| Chef::Config[:knife][:brightbox_secret] = key }

          option :brightbox_client_id,
            :short => "-A USERNAME",
            :long => "--brightbox-client-id USERNAME",
            :description => "Your brightbox API username",
            :proc => Proc.new { |username| Chef::Config[:knife][:brightbox_client_id] = username }

          option :brightbox_api_auth_url,
            :long => "--brightbox-api-auth-url URL",
            :description => "Your brightbox API auth url",
            :default => "https://api.gb1.brightbox.com",
            :proc => Proc.new { |url| Chef::Config[:knife][:brightbox_api_auth_url] = url }
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider => 'Brightbox',
            :brightbox_secret => Chef::Config[:knife][:brightbox_secret],
            :brightbox_client_id => (Chef::Config[:knife][:brightbox_client_id] || Chef::Config[:knife][:brightbox_api_username]),
            :brightbox_auth_url => Chef::Config[:knife][:brightbox_api_auth_url] || config[:brightbox_api_auth_url]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

    end
  end
end


