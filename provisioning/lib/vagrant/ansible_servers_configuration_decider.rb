require 'json'
require 'ostruct'

class AnsibleServersConfigurationDecider
  # @param [ServicesList] servers
  def initialize(servers:)
    @servers = servers
  end

  def decide(vagrant_context:)
    ansible_host_vars = {}

    @servers.all.each do |server|
      ansible_host_vars[server.name] = {
        'ip' => server.ip,
        'bootstrap_os' => 'centos',
        'flannel_interface' => server.ip,
        'flannel_backend_type' => 'host-gw',
        'local_release_dir' => '/vagrant/temp',
        'download_run_once' => 'False',
        # Override the default 'calico' with flannel.
        # inventory/group_vars/k8s-cluster.yml
        'kube_network_plugin' => 'flannel'
        # 'apiserver_custom_flags' => '--authorization-mode=RBAC' # https://kubernetes.io/docs/admin/authorization/rbac/
      }
    end

    vagrant_context.vm.provision 'ansible' do |ansible|
      ansible.playbook = File.join(File.dirname(__FILE__), 'inventory-playbook.yml')
      ansible.host_vars = ansible_host_vars
      ansible.groups = {
        'etcd' => @servers.names_for_tag('etcd'),
        'kube-master' => @servers.names_for_tag('kube-master'),
        'kube-node' => @servers.names_for_tag('kube-node'),
        'k8s-cluster:children' => ['kube-master', 'kube-node']
      }
      ansible.sudo = true
      ansible.limit = 'all'
      ansible.host_key_checking = false
    end
  end
end