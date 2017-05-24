# Requirements

| Tool          | Version       | Notes  |
| ------------- |:-------------:| -----: |
| vagrant       | >= 1.9.5    | Older versions have a bug which causes where the private ip network interface does not get started - https://github.com/mitchellh/vagrant/pull/8148 |
| ansible       | >= 2.3      |    |

 
# Setup

```bash
git submodule update --init --recursive
```

# Run local cluster

```bash
cd provisioning/local
vagrant up --parallel
vagrant status
```

```bash
cd configuration/kargo
ansible-playbook -i ../../provisioning/local/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory cluster.yml -b --flush-cache -v
```

# Kargo playbooks version

05/19/2017
sha: 9e6426786759f35563f663fd18942889f6de3a6c

# Links

https://www.vagrantup.com/docs/provisioning/ansible_intro.html
http://docs.ansible.com/ansible/guide_vagrant.html