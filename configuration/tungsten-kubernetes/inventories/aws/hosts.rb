#!/usr/bin/env ruby

require 'json'

ssh_private_key = ENV['SSH_PRIVATE_KEY'] || File.join(File.expand_path('~/.ssh'), 'tungsten_aws_rsa')
state_filename = ENV['TF_STATE'] || File.join(File.dirname(__FILE__),
                                              '..',
                                              '..',
                                              '..',
                                              '..',
                                              'provisioning',
                                              'aws',
                                              'terraform.tfstate')
terraform_state = JSON.parse(File.read(state_filename))

all_servers = terraform_state['modules']
                .map {|_module| _module['resources']}
                .flatten
                .reduce({}, :merge)
                .select {|_, attrs| attrs['type'] == 'aws_instance'}
                .map {|_, attrs| [_, attrs['primary']['attributes']]}
                .to_h

inventory = { '_meta' => { 'hostvars' => {} } }

def select_tags(attrs)
  attrs
    .select {|attr_name, attr_value| attr_name =~ /tags/ && attr_value == 'true'}
    .map {|tag, _| tag.gsub('tags.kargo-', '')}
    .flatten || []
end

all_servers.each do |server_name, attrs|
  name = server_name.split('.')[1]
  user = 'centos'
  port = 22
  public_ip = attrs['public_ip']
  private_ip = attrs['private_ip']
  tags = select_tags(attrs)
  inventory['_meta']['hostvars'][name] ={
    'ansible_host' => public_ip,
    'ansible_user' => user,
    'ansible_port' => port,
    'ansible_ssh_private_key_file' => ssh_private_key,
    'bootstrap_os' => 'centos'
  }

  tags.each do |tag|
    inventory[tag] ||=[]
    inventory[tag] << name
  end
  inventory['k8s-cluster'] = { 'children' => ['kube-master', 'kube-node'] }
end
puts inventory.to_json