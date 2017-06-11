require 'json'
require 'ostruct'

class ServersList
  def initialize(subnet:, servers:)
    @servers = servers
    initial_ip_suffix = 101
    @available_ips = @servers
                      .map { |servers_settings| servers_settings[:instances] }
                      .reduce(:+)
                      .times
                      .map {|index| "#{subnet}.#{initial_ip_suffix+index}"}
  end

  def all
    available_ips = @available_ips.dup
    @servers.map { |servers_settings| build_servers(servers_settings, available_ips) }.flatten
  end

  def names_for_tag(tag)
    all.select {|server| server.tags.include?(tag)}.map(&:name)
  end

  def build_servers(server_settings, available_ips)
    prefix = server_settings[:prefix]
    instances = server_settings[:instances]
    tags = server_settings[:tags]
    settings = server_settings[:settings]
    instances.times.map {|instance_number|
      JSON.parse(
        {
          name: "#{prefix}-#{instance_number.next}",
          ip: available_ips.delete_at(0),
          tags: tags,
          settings: settings
        }.to_json, object_class: OpenStruct
      )
    }
  end

  private :build_servers
end