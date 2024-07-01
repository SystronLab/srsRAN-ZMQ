## Setup with dockerised 5g core (recommended)

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

## Multi UE setup

Paste subscriber db file in srsRAN_project/docker/open5gs

In the same folder, edit the open5gs.env file

```bash
MONGODB_IP=127.0.0.1
OPEN5GS_IP=10.53.1.2
UE_IP_BASE=10.45.0
DEBUG=false
SUBSCRIBER_DB="subscriber_db.csv"
#SUBSCRIBER_DB=001010123456780,00112233445566778899aabbccddeeff,opc,63bfa50ee6523365ff14c1f45f88737d,8000,9,10.45.1.2
```

#### Add the Config Files in the Mentioned Locations

- **Location:** `srsRAN_Project/build/apps/gnb`

  - `gnb_zmq.yaml`

- **Location:** `srsRAN_4G/build/srsue/src`
  - `ue1_zmq.conf , ue2_zmq.conf, ue3_zmq.conf`

#### Running Open5GS

```bash
cd srsRAN_Project/docker/
docker compose up --build 5gc
```

#### Running the gNB

```bash
cd srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
sudo ip netns add ue2
sudo ip netns add ue3
sudo ./gnb -c ./gnb_zmq.yaml
```

#### Running the UEs in different terminals

```bash
cd srsRAN_4G/build/srsue/src
sudo ./srsue ue1_zmq.conf
sudo ./srsue ue1_zmq.conf
sudo ./srsue ue1_zmq.conf
```

while they are waiting to be attached install the GNU-Radio Companion

```bash
apt install xterm gnuradio
```

paste the multi_ue_scenario.grc in the parent folder

run it with

```bash
sudo gnuradio-companion multi_ue_scenario.grc
```

click on the play button in the companion, the UEs will then attach and get an IP address indicating successful connection

## Multi gNB setup

To connect the 2nd gNB to the same Open5gs running in docker, add a second IP address to the bridge interface connecting to the Open5gs docker container.

1. Get the name of the Open5gs docker bridge:

```bash
ip -o addr show | grep "10.53.1.1"
```

2. Add a second IP address to the bridge:

```bash
sudo ip addr add 10.53.1.3/24 dev BRIDGE_NAME
```

Create a copy of the gnb_zmq.yaml file and use the IP=10.53.1.3 as amf.bind_addr

Run the second gnb in a new terminal with

```bash
sudo ./gnb -c ./gnb2_zmq.yaml
```

The successful connection of the second gNB will be shown in the console of the 5g core.
