#!/bin/bash
# ***************************************************************************************
# - Script to set up things for creating an SSH server using Ngrok platform.
# - Downloads Ngrok utility and installs it for creating an SSH server.
# - Uses hosted virtual environment (i.e. Ubuntu) of GitHub to set up an SSH server.
# - Author:  Díwash (Diwash1001)
# - Version: generic:02
# - Date:    20230517
#
#       * Changes for v001 (20230517)  - make it clear that SSH Server is not ready
#       * Changes for v002 (20230518)  - make it clear that SSH server is ready
#
# ***************************************************************************************

# print message and quit
abort() {
  echo "$@";
  exit 1;
}

# create user and host
create_host_and_user() {
  echo "----------------------------------------------------------------";
  echo "-- Creating Host, User and Setting it up ...";
  echo "----------------------------------------------------------------";
  if [[ -n "${hostname}" && "${username}" && "${password}" ]]; then
      sudo hostname ${hostname}; # Creation of host
      sudo useradd -m ${username}; # Creation of user
      sudo adduser ${username} sudo; # Add user to sudo group
      echo "${username}:${password}" | sudo chpasswd; # Set password of user to 'root'
      sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd; # Change default shell from sh to bash
      echo "-- Host, User created and configured having hostname "${hostname}", username "${username}" and password "${password}".";
      echo "";
  else
      abort "-- Error: Unable to create host and user. Please ensure hostname, username, and password are provided.";
  fi
}

# download and install ngrok utility
install_ngrok_platform() {
  if [[ "$(uname)" =~ Linux ]]; then
      echo "----------------------------------------------------------------";
      echo "-- Downloading & Installing Ngrok Platform ...";
      echo "----------------------------------------------------------------";
      curl -fsSL https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok.zip;
      unzip ngrok.zip ngrok;
      rm ngrok.zip;
      chmod +x ngrok;
      sudo mv ngrok /usr/local/bin;
      ngrok -v;
      echo "";
  else
      abort "-- Failed to install Ngrok Package! System not supported.";
  fi
}

# start ngrok and create a proxy for ssh port (i.e. 22)
config_ngrok_ssh_port() {
  local log_file=".ngrok.log";
  echo "----------------------------------------------------------------";
  echo " -- Starting Ngrok & Creating A Proxy For SSH Port (i.e. 22) ...";
  echo "----------------------------------------------------------------";
  if [[ -e "${log_file}" && -n "${ngrok_token}" && "${ngrok_region}" ]]; then
      screen -dmS ngrok \
          ngrok tcp 22 \
          --log "${log_file}" \
          --authtoken "${ngrok_token}" \
          --region "${ngrok_region}";
  else
       abort "-- Error: Unable to create a proxy for SSH port (i.e 22). Please ensure ngrok authtoken and ngrok region are provided.";
  fi
  echo "----------------------------------------------------------------";
  echo " -- Generating Log File. Please Wait ...";
  echo "----------------------------------------------------------------";
  sleep 10;
  echo "";
}

# generate a command to connect to this session
start_ngrok_ssh_server() {
  local log_file=".ngrok.log";
  local errors_log="$(grep "command failed" < ${log_file})";
  if [[ -e "${log_file}" && -z "${errors_log}" ]]; then
      ssh_cmd="$(grep -oE "tcp://(.+)" ${log_file} | sed "s/tcp:\/\//ssh ${username}@/" | sed "s/:/ -p /")";
      echo "----------------------------------------------------------------";
      echo "-- To Connect, Copy & Paste The Following Command Into Terminal:";
      echo "----------------------------------------------------------------";
      echo "-- ${ssh_cmd}";
  else
      abort "-- Error Occurred! ${errors_log}";
  fi
}

# do all the work!
WorkNow() {
    local SCRIPT_VERSION="20230517";
    local START=$(date);
    local STOP=$(date);
    echo "$0, v$SCRIPT_VERSION";
    create_host_and_user;
    install_ngrok_platform;
    config_ngrok_ssh_port;
    start_ngrok_ssh_server;
    echo "-- Start time = $START";
    echo "-- Stop time = $STOP";
    exit 0;
}

# --- main() ---
WorkNow;
# --- end main() ---
