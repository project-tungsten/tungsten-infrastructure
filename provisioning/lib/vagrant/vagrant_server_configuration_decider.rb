require 'json'
require 'ostruct'

class VagrantServerConfigurationDecider
  def initialize(server:)
    @server = server
  end

  def decide(vagrant_context:)
    vagrant_context.vm.define @server.name do |server_config|

      server_config.vm.hostname = @server.name
      server_config.vm.network :private_network, ip: @server.ip

      server_config.vm.provider :virtualbox do |vb|
        vb.name = @server.name
        vb.gui = false

        vb.memory = @server.settings.memory
        vb.cpus = @server.settings.cpus
        vb.linked_clone = true
        vb.customize ['modifyvm', :id, '--cpuexecutioncap', '50']
      end
    end
  end
end