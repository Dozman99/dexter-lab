sudo apt install openssh-server -y

ssh dozman@192.168.0.5 'mkdir -p .ssh && cat >> .ssh/authorized_keys' < ~/.ssh/id_rsa.pub

sudo apt install vim -y

sudo apt-get install git-core -y
sudo apt install curl -y
sudo apt install make -y
sudo apt install net-tools -y

sudo apt-get install tree


cat /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/ip_forward
# or
sysctl -w net.ipv4.ip_forward=1
# or
sudo vim /etc/sysctl.conf

sudo apt-get update && sudo apt-get -y install golang-go 
export PATH=$PATH:$(go env GOPATH)/bin


mkdir ~/cni-plugins
cd ~/cni-plugins
git clone https://github.com/containernetworking/plugins.git .
./build_linux.sh



mkdir ~/tc-redirect-tap
cd ~/tc-redirect-tap
git clone https://github.com/awslabs/tc-redirect-tap.git .
git checkout <commit_hash>
make all

sudo mkdir -p /firecracker/cni/bin
sudo cp ~/cni-plugins/bin/* /firecracker/cni/bin/
sudo cp ~/tc-redirect-tap/tc-redirect-tap /firecracker/cni/bin/tc-redirect-tap


sudo mkdir -p /opt/cni
sudo mv /firecracker/cni/bin /opt/cni/bin

sudo mkdir -p /etc/cni/net.d
sudo sh -c 'cat > /etc/cni/net.d/firecracker_cni.conflist << EOF
{
  "cniVersion": "0.4.0",
  "name": "firecracker",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "dozbr0",
      "isDefaultGateway": true,
      "ipam": {
        "type": "host-local",
        "resolvConf": "/etc/resolv.conf",
        "dataDir": "/srv/vm/networks",
        "subnet": "10.0.30.0/24",
        "rangeStart": "10.0.30.32",
        "gateway": "10.0.30.1"
      }
    },
    {
      "type": "firewall"
    },
    {
      "type": "tc-redirect-tap"
    }
  ]
}
EOF'

    
# sudo mkdir -p /opt/cni
# sudo ln -sfn /firecracker/cni/bin /opt/cni/bin
# sudo mkdir -p /etc/cni/net.d


go install github.com/containernetworking/cni/cnitool@latest
sudo mv $(go env GOPATH)/bin/cnitool /usr/local/bin && cnitool
###########################################################################

ARCH="$(uname -m)"
# Download a linux kernel binary
wget https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.9/${ARCH}/vmlinux-5.10.217

# Download a rootfs
wget https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.9/${ARCH}/ubuntu-22.04.ext4

# Download the ssh key for the rootfs
wget https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.9/${ARCH}/ubuntu-22.04.id_rsa

# Set user read permission on the ssh key
chmod 400 ./ubuntu-22.04.id_rsa

# sudo mkdir -p /etc/cni/net.d
# sudo cp firecracker_cni.conflist  /etc/cni/net.d/ 

sudo groupadd jailer && getent group jailer
sudo useradd -g jailer jailer && id jailer 


sudo mkdir -p /srv/vm/{configs,filesystems,kernels,linux.git,networks,jailer}
sudo cp  vmlinux-5.10.217   /srv/vm/kernels/vmlinux-5.10.217
sudo cp ubuntu-22.04.ext4 /srv/vm/filesystems/ubuntu-22.04.ext4

chmod +x ./firecracker.sh 
sudo ./firecracker.sh 

chmod +x ./vmctl
./vmctl create --id $(uuidgen) --template ./vm_config.json