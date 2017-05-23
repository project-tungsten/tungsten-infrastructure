# Requirements

vagrant >= 1.8.0
ansible >= 2.3

# Run local cluster

```bash
cd provisioning/local
vagrant up --parallel
vagrant status

cd configuration
ansible-playbook -i ../provisioning/local/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory cluster.yml -b -v
```

# Kargo playbooks version

05/19/2017
sha: 9e6426786759f35563f663fd18942889f6de3a6c

# Links

https://www.vagrantup.com/docs/provisioning/ansible_intro.html
http://docs.ansible.com/ansible/guide_vagrant.html