# srsRAN setup guide

Guide to setup the srsRAN with FlexRIC and OSCRIC

## Create Parent Folder

```bash
mkdir srsRAN_parent
cd srsRAN_parent
```

## Install Dependencies

```bash
sudo apt-get install git cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev
```

## Add ZMQ in the Parent Folder

```bash
sudo apt-get install libzmq3-dev

git clone https://github.com/zeromq/libzmq.git
cd libzmq
./autogen.sh
./configure
make
sudo make install
sudo ldconfig

git clone https://github.com/zeromq/czmq.git
cd czmq
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
```

## Add 5g in the Parent Folder

```bash
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j`nproc`
sudo make install
sudo ldconfig
```

## Add 4g in the Parent Folder (we need it for the UE simulator)

```bash
sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev

git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
make
make test
sudo make install
srsran_install_configs.sh user
```

## Add UHD in the Parent Folder

```bash
sudo apt-get install autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool \
g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev \
libusb-dev python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools \
python3-ruamel.yaml

git clone https://github.com/EttusResearch/uhd.git
cd uhd/host
mkdir build
cd build
cmake ../
make
make test # This step is optional
sudo make install
sudo ldconfig
```

## Add Open5GS in the Parent Folder

```bash
sudo apt update
sudo apt install gnupg
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod # if '/usr/bin/mongod' is not running
sudo systemctl enable mongod # ensure to automatically start it on system boot

sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs
```

## Installing WebUI of Open5GS

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=20

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt update
sudo apt install nodejs -y

curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

After the installation is done, the WebUI will be accessible on `localhost:9999`. The login credentials are:

- **Username:** admin
- **Password:** 1423

After logging in, click on the `+` sign and add the following details from `ue_zmq.conf` file given in the config folder:

- **IMSI:** imsi
- **Subscriber key:** k
- **Operator key:** opc
- **DNN/APN:** apn
- **Type:** IPv4

Click on 'Save'.

## Add the Config Files in the Mentioned Locations

- **Location:** `/etc/open5gs`

  - `amf.yaml`
  - `nrf.yaml`

- **Location:** `srsRAN_Project/build/apps/gnb`

  - `gnb_zmq.yaml`

- **Location:** `srsRAN_4G/build/srsue/src`
  - `ue_zmq.conf`

## Running the Setup

### Restarting the Core

```bash
sudo systemctl restart open5gs-*
```

### Running the gNB

```bash
cd srsRAN_Project/build/apps/gnb
sudo ip netns add ue1
sudo ./gnb -c ./gnb_zmq.yaml
```

### Running the UE

```bash
cd srsRAN_4G/build/srsue/src
sudo ./srsue ue_zmq.conf
```

You will get an IP address for the UE indicating successful connection to gNB.
