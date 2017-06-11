# Requirements

| Tool          | Version       | Notes  |
| ------------- |:-------------:| -----: |
| vagrant       | >= 1.9.5      | Older versions have a bug where the private ip network interface does not get started - https://github.com/mitchellh/vagrant/pull/8148 |
| ansible       | >= 2.3        |        |
| kubectl       |               |        |
| helm          | = v2.2.2      | https://kubernetes-helm.storage.googleapis.com/helm-v2.2.2-darwin-amd64.tar.gz       |

 
# Setup

```bash
git submodule update --init --recursive
vagrant plugin install vagrant-persistent-storage --plugin-version 0.0.26
```

# Run local cluster

```bash
VAGRANT_CWD=provisioning/local vagrant up --parallel
VAGRANT_CWD=provisioning/local vagrant status
```

```bash
ANSIBLE_CONFIG=configuration/kargo/ansible.cfg ansible-playbook -i provisioning/local/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory configuration/tungsten-kubernetes/cluster.yml -b --flush-cache -v
kubectl get pods --kubeconfig=configuration/kubectl/local/config --all-namespaces
```

# Run mini-local cluster

```bash
VAGRANT_CWD=provisioning/mini-local vagrant up 
VAGRANT_CWD=provisioning/mini-local vagrant status
```

```bash
ANSIBLE_CONFIG=configuration/kargo/ansible.cfg ansible-playbook -i provisioning/mini-local/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory configuration/tungsten-kubernetes/cluster.yml -b --flush-cache -v
kubectl get pods --kubeconfig=configuration/kubectl/local/config --all-namespaces
```

## Deploy Services

### Nginx Ingress Controller

```bash
kubectl apply -f configuration/services/nginx-ingress-controller/ --kubeconfig=configuration/kubectl/local/config
curl http://172.168.10.103
```

### Kubernetes Dashboard

```bash
kubectl apply -f configuration/services/kubernetes-dashboard/ --kubeconfig=configuration/kubectl/local/config
kubectl proxy --kubeconfig=configuration/kubectl/local/config
open http://localhost:8001/ui
```

### Concourse
```bash
KUBECONFIG=configuration/kubectl/local/config helm init --client-only
KUBECONFIG=configuration/kubectl/local/config helm install --name concourse stable/concourse --set persistence.enabled=false,postgresql.persistence.enabled=false,worker.replicas=1,worker.resources.requests.cpu="100m",worker.resources.requests.memory="128Mi"

export POD_NAME=$(kubectl get pods --namespace default -l "app=concourse-web" -o jsonpath="{.items[0].metadata.name}" --kubeconfig=configuration/kubectl/local/config)
echo "Visit http://127.0.0.1:8080 to use Concourse"
kubectl port-forward --namespace default $POD_NAME 8080:8080 --kubeconfig=configuration/kubectl/local/config
echo "Login with the following credentials: concourse:concourse"
```

### Concourse (Uninstall)
```bash
KUBECONFIG=configuration/kubectl/local/config helm delete --purge concourse
```
# Links

https://www.vagrantup.com/docs/provisioning/ansible_intro.html
http://docs.ansible.com/ansible/guide_vagrant.html
https://github.com/gluster/gluster-kubernetes/tree/master/docs/presentations
https://github.com/gluster/gluster-kubernetes
https://github.com/heketi/heketi/wiki/Kubernetes-Integration
https://github.com/heketi/heketi
http://blog.lwolf.org/post/how-i-deployed-glusterfs-cluster-to-kubernetes/