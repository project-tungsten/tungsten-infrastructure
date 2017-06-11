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
        # vb.linked_clone = true
        vb.customize ['modifyvm', :id, '--cpuexecutioncap', '50']

        unless @server.settings.volumes.nil?
          @server.settings.volumes.each_with_index do |volume, volume_index|
            disk_location = File.join(ENV['WORKING_DIR'],
                                      '.volumes',
                                      @server.name,
                                      "#{volume.name}.vdi")
            disk_size = volume.size_in_gb * 1024
            disk_controller = "SATA Controller"

            if !File.exist?(disk_location)
              vb.customize ['createhd', '--filename', disk_location, '--variant', 'Fixed', '--size', disk_size]
              # vb.customize ['storagectl', :id, '--name', disk_controller, '--add', 'sata', '--portcount', 1]
            end
            vb.customize ['storageattach', :id, '--storagectl', disk_controller, '--port', volume_index + 2, '--device', 0, '--type', 'hdd', '--medium', disk_location]
          end

        end
        # config.vm.provision "shell", inline: <<-SHELL
        #   sudo mkfs.ext4 /dev/sdb
        # SHELL
      end
    end
  end
end