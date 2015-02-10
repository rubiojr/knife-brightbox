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
    class BrightboxServerCreate < Knife

      include Knife::BrightboxBase

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife brightbox server create (options)"

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server; default is NANO (512 MB)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = (f || 'nano') },
        :default => 'nano'

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i }

      option :server_groups,
        :short => "-g grp-xxxxx,gpr-yyyyy",
        :long => "--server-groups grp-xxxxx,gpr-yyyyy",
        :description => "Server groups to place server in (comma delimited)",
        :proc => Proc.new { |server_groups| server_groups.split(',') },
        :default => []

      option :server_name,
        :short => "-S NAME",
        :long => "--server-name NAME",
        :description => "The server name"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu10.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :secret,
        :short => "-s SECRET",
        :long => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'root'",
        :default => "root"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => 22,
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key.to_i }

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) },
        :default => {}

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :zone,
        # no short switch because -z is --local-mode
        :long => "--zone ZONE",
        :description => "Brightbox zone; default is gb1-a. Can also be gb1-b",
        :default => 'gb1-a',
        :proc => Proc.new { |z| Chef::Config[:zone] = z }

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, config[:ssh_port])
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT, Errno::EPERM
        false
      rescue Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true

        unless config[:image]
          ui.error("You have not provided a valid image value.  Please note the short option for this value recently changed from '-i' to '-I'.")
          exit 1
        end

        print "#{ui.color("Creating server... ", :magenta)}"
        server = connection.servers.create(
          :name => config[:server_name] || config[:chef_node_name],
          :image_id => config[:image],
          :zone_id => zone_id,
          :flavor_id => config[:flavor]
        )
        puts " done \n"

        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{ui.color("Image", :cyan)}: #{server.image.name}"
        puts "#{ui.color("Zone", :cyan)}: #{server.zone['handle']}"

        print "\n#{ui.color("Waiting server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; service.servers.get(server.id).ready? }

        puts("\n")

        print "#{ui.color("Creating cloud ip ", :magenta)}"
        ip = connection.create_cloud_ip
        cip = connection.cloud_ips.get ip['id']
        destination_id = server.interfaces.last['id']
        cip.map destination_id
        server.wait_for { print "."; service.cloud_ips.get(ip['id']).mapped? }
        puts " done\n"

        server = connection.servers.get(server.id)
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.private_ip_address}"

        config[:server_groups].each do |server_group|
          connection.add_servers_server_group(server_group,
                                              :servers => [{ :server => server.id }])
        end

        print "\n#{ui.color("Bootstrapping server ", :magenta)}"
        print "\n#{ui.color("Waiting for sshd ", :magenta)}"
        print(".") until tcp_test_ssh(server.public_ip_address) { sleep @initial_sleep_delay ||= 10; puts(" done") }
        bootstrap_for_node(server).run

        puts "\n"
        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{ui.color("Image", :cyan)}: #{server.image.name}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.private_ip_address}"
        puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
        puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [server.cloud_ips.first['public_ip']]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.name || server.id
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:first_boot_attributes] = config[:first_boot_attributes]
        bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
        bootstrap
      end

      private

      # Get zone identifiers from Brightbox's API (example: `zon-ca1g2`) and
      # their handle (example: `gb1-a`). They are not necessarily the same
      # on every user account.
      def zones
        connection.zones.inject({}) do |memo, z|
          memo[z.handle] = z.id

          memo
        end
      end

      def zone_id
        zone_handle = config[:zone]

        begin
          zones.fetch(zone_handle)
        rescue KeyError
          ui.error <<-EOF
This is not a valid zone: #{zone_handle}

Valid zones: #{zones.keys.join(', ')}
          EOF

          exit 1
        end
      end
    end
  end
end
