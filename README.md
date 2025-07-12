
# Vagrantfile and Scripts to Automate k8s Setup using Kubeadm and Containerd.

## Credits

This code is a modified copy to be used when containerd is required.
The original source code/project using CRI-O can be found [here](https://github.com/techiescamp/vagrant-kubeadm-kubernetes).


## Prerequisites

1. Working Vagrant setup
2. CPU, RAM and Disk - Resources available according to the desired configuration.

## For MAC/Linux Users

The latest version of Virtualbox for Mac/Linux can cause issues.

Create/edit the /etc/vbox/networks.conf file and add the following to avoid any network-related issues.
<pre>* 0.0.0.0/0 ::/0</pre>

or run below commands

```shell
sudo mkdir -p /etc/vbox/
echo "* 0.0.0.0/0 ::/0" | sudo tee -a /etc/vbox/networks.conf
```

So that the host only networks can be in any range, not just 192.168.56.0/21 as described here:
https://discuss.hashicorp.com/t/vagrant-2-2-18-osx-11-6-cannot-create-private-network/30984/23

## Bring Up the Cluster

To provision the cluster, execute the following commands.

```shell
git clone https://github.com/acmano7/vagrant-kubeadm-k8s-containerd.git
cd vagrant-kubeadm-k8s-containerd
vagrant up
```
## Set Kubeconfig file variable

```shell
cd configs
export KUBECONFIG=$(pwd)/config
```

or you can copy the config file to .kube directory.

```shell
cp config ~/.kube/
```

## Install Kubernetes Dashboard

The dashboard is automatically installed by default, but it can be skipped by commenting out the dashboard version in _settings.yaml_ before running `vagrant up`.

If you skip the dashboard installation, you can deploy it later by enabling it in _settings.yaml_ and running the following:
```shell
vagrant ssh -c "/vagrant/scripts/dashboard.sh" master
```

## Kubernetes Dashboard Access

To get the login token, copy it from _config/token_ or run the following command:
```shell
kubectl -n kubernetes-dashboard get secret/dashboard-admin-user -o 'go-template={{.data.token | base64decode}}'
```

Forward Kubernetes Dashboard service port:
```shell
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

Open the site in your browser:
```shell
https://localhost:8443
```

## To shutdown the cluster,

```shell
vagrant halt
```

## To restart the cluster,

```shell
vagrant up
```

## To destroy the cluster,

```shell
vagrant destroy -f
```

## Contributing

Contributions are always welcome!
