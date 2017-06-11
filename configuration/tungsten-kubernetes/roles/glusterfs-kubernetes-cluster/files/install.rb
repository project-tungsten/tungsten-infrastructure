#!/usr/bin/env ruby

require 'json'
require 'tempfile'

Dir.chdir File.dirname(__FILE__)

kubectl_bin='/usr/local/bin/kubectl'
puts "fetch nodes to be used as persistent volumes"
storage_node_names=`#{kubectl_bin} get nodes -o name | grep server`.split("\n").join(' ').gsub('nodes/', '')
puts storage_node_names

# Taint and label nodes to enforce only glusterfs
#system("#{kubectl_bin} taint nodes #{storage_node_names} persistent-volume=true:NoSchedule --overwrite=true")
#system("#{kubectl_bin} taint nodes #{storage_node_names} persistent-volume=true:NoExecute --overwrite=true")

# Not required since label by gk-deploy script
# system("kubectl label nodes #{storage_node_names} persistent-volume=true --overwrite=true")

storage_nodes_payload = JSON.parse(`#{kubectl_bin} get nodes #{storage_node_names} -o json`)
storage_nodes = storage_nodes_payload['items'] || [storage_nodes_payload]

topology = {
  'clusters' => [
    {
      'nodes' => []
    }
  ]
}

storage_nodes.each do |node|
  ip = node['status']['addresses'].find { |address| address['type'] == 'InternalIP' }['address']
  hostname = node['status']['addresses'].find { |address| address['type'] == 'Hostname' }['address']
  topology['clusters'].first['nodes'] <<
    {
      'node' => {
        'hostnames' => {
          'manage' => [
            hostname
          ],
          'storage' => [
            ip
          ]
        },
        'zone' => 1
      },
      'devices' => [
        '/dev/sdb'
      ]
    }
end

puts topology

topology_file = Tempfile.new(['glusterfs_topology', '.json'])
topology_file.write topology.to_json
topology_file.close

kube_templates_path = File.expand_path('kube-templates')

deployer = File.expand_path('glusterfs-kubernetes/deploy/gk-deploy')
deploy_command = [
  deployer,
  topology_file.path,
  '-g',
  "--cli #{kubectl_bin}",
  '-v',
  "--templates_dir #{kube_templates_path}",
  '--yes',
  '-w 600',
  '--admin-key heketi-admin-user',
  '--user-key heketi-volume-user'
].join(' ')

puts "running: #{deploy_command}"

system deploy_command



