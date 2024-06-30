#!/bin/bash

# Current working directory - srsRAN parent
# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define the directories to open (relative to the script's directory)
# DIR1="$SCRIPT_DIR/srsRAN_Project/docker/" # open5gs docker deployment, docker compose up 5gc
DIR1="$SCRIPT_DIR" # FlexRIC - ./flexric/build/examples/ric/nearRT-RIC
DIR2="$SCRIPT_DIR/srsRAN_Project/build/apps/gnb" # gNB - sudo ./gnb -c gnb_zmq.yaml e2 --addr="127.0.0.1" --bind_addr="127.0.0.1"
DIR3="$SCRIPT_DIR/srsRAN_4G/build/srsue/src"  # UE - sudo ./srsue ue_zmq.conf
DIR4="$SCRIPT_DIR"  # FlexRIC xApp - ./flexric/build/examples/xApp/c/monitor/xapp_oran_moni


# Define geometry for terminals (width x height + x offset + y offset)
GEOM1="80x24+100+100"
GEOM2="80x24+900+100"
GEOM3="80x24+100+550"
GEOM4="80x24+900+550"


# Open new terminal windows with the specified directories
# Step 1 and 2 - Open5GS and FlexRIC
gnome-terminal --working-directory="$DIR1" --geometry="$GEOM1"
# -- bash -c "sudo systemctl restart open5gs-*; ./flexric/build/examples/ric/nearRT-RIC; exec bash"

# sleep 2

# Step 3 - gNB
gnome-terminal --working-directory="$DIR2" --geometry="$GEOM2"
# -- bash -c "sudo ip netns add ue1; sudo ip netns list; sudo ./gnb -c gnb_zmq.yaml e2 --addr='127.0.0.1' --bind_addr='127.0.0.1'; exec bash"


# Step 4 - UE
gnome-terminal --working-directory="$DIR3" --geometry="$GEOM3"
# -- bash -c "sudo ./srsue ue_zmq.conf; exec bash"

# Step 5 - Start IP traffic (e.g. ping)
 # 

# Step 6 - xApp
gnome-terminal --working-directory="$DIR4" --geometry="$GEOM4"
# -- bash -c "./flexric/build/examples/xApp/c/monitor/xapp_oran_moni; exec bash"


