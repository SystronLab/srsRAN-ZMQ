### Install docker

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update


sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world

```

### Running the setup with one gNB and one UE

#### Add the Config Files in the Mentioned Locations

- **Location:** `srsRAN_Project/build/apps/gnb`

  - `single_gnb_zmq.yaml`

- **Location:** `srsRAN_4G/build/srsue/src`
  - `single_ue_zmq.conf`

#### Running Open5GS

```bash
cd srsRAN_Project/docker/
docker compose up --build 5gc
```

#### Running the gNB

```bash
cd srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
sudo ./gnb -c ./single_gnb_zmq.yaml
```

#### Running the UE

```bash
cd srsRAN_4G/build/srsue/src
sudo ./srsue single_ue_zmq.conf
```

You will get an IP address for the UE indicating successful connection to gNB.

## UE Traffic Testing

Routing:

```bash
sudo ip ro add 10.45.0.0/16 via 10.53.1.2

sudo ip netns exec ue1 ip route add default via 10.45.1.1 dev tun_srsue
```

Ping:

Uplink:

```bash
sudo ip netns exec ue1 ping 10.45.1.1

```

Downlink:

```bash
ping 10.45.1.2
```

## Iperf3 for testing throughput

```bash
sudo apt install iperf3
```

In a new terminal start server on network side:

```bash
iperf3 -s -i 1
```

In a new terminal start UDP/TCP Stream on UE side:

TCP

```bash
sudo ip netns exec ue1 iperf3 -c 10.53.1.1 -i 1 -t 60
```

or UDP

```bash
sudo ip netns exec ue1 iperf3 -c 10.53.1.1 -i 1 -t 60 -u -b 10M

```
