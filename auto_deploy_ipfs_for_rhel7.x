cd /opt
wget https://dist.ipfs.io/go-ipfs/v0.4.20/go-ipfs_v0.4.20_linux-amd64.tar.gz
wget https://dist.ipfs.io/ipfs-cluster-ctl/v0.10.1/ipfs-cluster-ctl_v0.10.1_linux-amd64.tar.gz
wget https://dist.ipfs.io/ipfs-cluster-service/v0.10.1/ipfs-cluster-service_v0.10.1_linux-amd64.tar.gz
wget ipfs-swarm-key-gen

tar -xzf go-ipfs_v0.4.20_linux-amd64.tar.gz
tar -xzf ipfs-cluster-ctl_v0.10.1_linux-amd64.tar.gz
tar -xzf ipfs-cluster-service_v0.10.1_linux-amd64.tar.gz

chmod 755 ./go-ipfs/install.sh
./go-ipfs/install.sh

cp /opt/ipfs-cluster-ctl/ipfs-cluster-ctl  /usr/bin/
cp /opt/ipfs-cluster-service/ipfs-cluster-service /usr/bin

echo 'export LIBP2P_FORCE_PNET=1' >> /etc/profile
export LIBP2P_FORCE_PNET=1
ipfs init
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config --json Bootstrap "[]"

cd /opt
chmod 755 ipfs-swarm-key-gen
./ipfs-swarm-key-gen > ./swarm.key
cp /opt/swarm.key ~/.ipfs/swarm.key

systemctl stop firewalld.service
systemctl disable firewalld.service

grep -i "^SELINUX=disabled" /etc/selinux/config
if [ $? -eq 0 ] ;then 
    echo "selinux disbaled"
else
    echo "selinux check ERROR!!!"
    exit 1
fi

echo '[Unit]' > /usr/lib/systemd/system/ipfs.service
echo 'Description=IPFS daemon' >> /usr/lib/systemd/system/ipfs.service
echo 'After=network.target' >> /usr/lib/systemd/system/ipfs.service
echo '' >> /usr/lib/systemd/system/ipfs.service
echo '[Service]' >> /usr/lib/systemd/system/ipfs.service
echo 'Environment="IPFS_FD_MAX=4096"' >> /usr/lib/systemd/system/ipfs.service
echo 'Environment="LIBP2P_FORCE_PNET=1"' >> /usr/lib/systemd/system/ipfs.service
#echo 'Environment="IPFS_PATH=/home/ipfsrepo"' >> /usr/lib/systemd/system/ipfs.service
echo 'ExecStart=/usr/local/bin/ipfs daemon --migrate' >> /usr/lib/systemd/system/ipfs.service
echo 'Restart=on-failure' >> /usr/lib/systemd/system/ipfs.service
echo 'User=root' >> /usr/lib/systemd/system/ipfs.service
echo '' >> /usr/lib/systemd/system/ipfs.service
echo '[Install]' >> /usr/lib/systemd/system/ipfs.service
echo 'WantedBy=multi-user.target' >> /usr/lib/systemd/system/ipfs.service



ipfs-cluster-service init

sed -i 's/127.0.0.1/0.0.0.0/g' /root/.ipfs-cluster/service.json

echo '[Unit]' > /usr/lib/systemd/system/ipfs-cluster.service
echo 'Description=IPFS Cluster Service' >> /usr/lib/systemd/system/ipfs-cluster.service
echo 'After=network.target' >> /usr/lib/systemd/system/ipfs-cluster.service
echo '' >> /usr/lib/systemd/system/ipfs-cluster.service
echo '[Service]' >> /usr/lib/systemd/system/ipfs-cluster.service
echo 'ExecStart=/usr/bin/ipfs-cluster-service daemon --upgrade' >> /usr/lib/systemd/system/ipfs-cluster.service
echo 'Restart=on-failure' >> /usr/lib/systemd/system/ipfs-cluster.service
echo 'User=root' >> /usr/lib/systemd/system/ipfs-cluster.service
echo '' >> /usr/lib/systemd/system/ipfs-cluster.service
echo '[Install]' >> /usr/lib/systemd/system/ipfs-cluster.service
echo 'WantedBy=multi-user.target' >> /usr/lib/systemd/system/ipfs-cluster.service

systemctl daemon-reload 

systemctl enable ipfs.service
ipfs bootstrap rm --all
systemctl restart ipfs.service

systemctl enalbe ipfs-cluster.service 
systemctl restart ipfs-cluster.service 
