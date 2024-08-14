#!/bin/bash

# Cetak pesan dan keluar
abort() {
  echo "$@";
  exit 1;
}

# Buat host dan pengguna
create_host_and_user() {
  echo "----------------------------------------------------------------";
  echo "-- Membuat Host, Pengguna, dan Menyetingnya ...";
  echo "----------------------------------------------------------------";
  if [[ -n "${hostname}" && -n "${username}" && -n "${password}" ]]; then
      sudo hostname ${hostname}; # Membuat host
      sudo useradd -m ${username}; # Membuat pengguna
      sudo adduser ${username} sudo; # Menambahkan pengguna ke grup sudo
      echo "${username}:${password}" | sudo chpasswd; # Mengatur kata sandi pengguna
      sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd; # Mengubah shell default dari sh ke bash
      echo "-- Host dan Pengguna dibuat dan dikonfigurasi dengan hostname "${hostname}", username "${username}" dan password "${password}".";
      echo "";
  else
      abort "-- Error: Tidak dapat membuat host dan pengguna. Pastikan hostname, username, dan password disediakan.";
  fi
}

# Unduh dan instal utilitas ngrok
install_ngrok_platform() {
  if [[ "$(uname)" =~ Linux ]]; then
      echo "----------------------------------------------------------------";
      echo "-- Mengunduh & Menginstal Platform Ngrok ...";
      echo "----------------------------------------------------------------";
      curl -fsSL https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-v3-stable-linux-amd64.zip -o ngrok.zip;
      unzip -q ngrok.zip ngrok;
      rm ngrok.zip;
      chmod +x ngrok;
      sudo mv ngrok /usr/local/bin;
      ngrok -v;
      echo "";
  else
      abort "-- Gagal menginstal Paket Ngrok! Sistem tidak didukung.";
  fi
}

# Mulai ngrok dan buat proxy untuk port ssh (i.e. 22)
config_ngrok_ssh_port() {
  local log_file=".ngrok.log";
  echo "----------------------------------------------------------------";
  echo " -- Memulai Ngrok & Membuat Proxy Untuk Port SSH (i.e. 22) ...";
  echo "----------------------------------------------------------------";

  if [[ -n "${ngrok_token}" && -n "${ngrok_region}" ]]; then
      # Hapus log file lama jika ada
      rm -f "${log_file}"

      # Coba memulai ngrok
      screen -dmS ngrok \
          ngrok tcp 22 \
          --log "${log_file}" \
          --authtoken "${ngrok_token}" \
          --region "${ngrok_region}";

      # Cek apakah ngrok berjalan
      if [[ $? -ne 0 ]]; then
          abort "-- Error: Gagal memulai ngrok. Periksa instalasi ngrok dan konfigurasi screen.";
      fi
      
  else
       abort "-- Error: Tidak dapat membuat proxy untuk port SSH (i.e 22). Pastikan ngrok authtoken dan ngrok region disediakan.";
  fi

  echo "----------------------------------------------------------------";
  echo " -- Menghasilkan File Log. Harap Tunggu ...";
  echo "----------------------------------------------------------------";
  sleep 10;

  # Periksa log untuk melihat apakah ngrok berhasil dijalankan
  if [[ -e "${log_file}" ]]; then
      cat "${log_file}"
  else
      abort "-- Error: Log file ngrok tidak ditemukan.";
  fi

  echo "";
}

# Buat perintah untuk terhubung ke sesi ini
start_ngrok_ssh_server() {
  local log_file=".ngrok.log";
  local errors_log="$(grep "command failed" < ${log_file})";
  if [[ -e "${log_file}" && -z "${errors_log}" ]]; then
      ssh_cmd="$(grep -oE "tcp://(.+)" ${log_file} | sed "s/tcp:\/\//ssh ${username}@/" | sed "s/:/ -p /")";
      echo "----------------------------------------------------------------";
      echo "-- Untuk Terhubung, Salin & Tempel Perintah Berikut ke Terminal:";
      echo "----------------------------------------------------------------";
      echo "-- ${ssh_cmd}";
  else
      abort "-- Terjadi Kesalahan! ${errors_log}";
  fi
}

# Lakukan semua pekerjaan!
WorkNow() {
    local SCRIPT_VERSION="20230517";
    local START=$(date);
    local STOP=$(date);
    echo "$0, v$SCRIPT_VERSION";
    create_host_and_user;
    install_ngrok_platform;
    config_ngrok_ssh_port;
    start_ngrok_ssh_server;
    echo "-- Waktu Mulai = $START";
    echo "-- Waktu Selesai = $STOP";
    exit 0;
}

# --- main() ---
WorkNow;
# --- end main() ---
