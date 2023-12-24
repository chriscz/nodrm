#!/bin/bash
safemode_off () { set +eu; }
safemode_on () { set -euo pipefail; }

safemode_on

# TO DEBUG
# set -x 

prepare () {
  safemode_off

  # Download wine
  wget -c https://raw.githubusercontent.com/scottyhardy/docker-wine/master/docker-wine -O /tmp/docker-wine
  cp /tmp/docker-wine .

  chmod +x docker-wine

  # Download Python 3
  wget -c https://www.python.org/ftp/python/3.7.9/python-3.7.9-amd64.exe -O /tmp/python-installer.exe
  cp /tmp/python-installer.exe .

  # Download De-DRM
  wget -c https://github.com/noDRM/DeDRM_tools/archive/refs/tags/v10.0.3.tar.gz -O /tmp/dedrm.tar.gz
  cp /tmp/dedrm.tar.gz .

  mkdir -p dedrm/
  tar -xaf dedrm.tar.gz -C ./dedrm

  # Download Adobe Digital Editions
  wget -c http://download.adobe.com/pub/adobe/digitaleditions/ADE_2.0_Installer.exe -O /tmp/adeinstaller.exe
  cp /tmp/adeinstaller.exe .

  safemode_on
}

run () {
  ./docker-wine --mount="type=bind,source=./,target=/mnt" --env="LIBGL_ALWAYS_SOFTWARE=1" "$@"
}

shell () {
  run bash
}

install () {
  # Allow Docker to write to this directory
  chmod a+w .

  run wineboot
  run winetricks -q corefonts dotnet35sp1
  run wine /mnt/python-installer.exe /passive InstallAllUsers=1 PrependPath=1
  run wine python -m pip install pycryptodome apsw lxml
  run wine /mnt/adeinstaller.exe
}

adobe_digital_editions () {
  run wine "/home/wineuser/.wine/drive_c/Program Files (x86)/Adobe/Adobe Digital Editions 2.0/DigitalEditions.exe"
}

extract_ade_key () {
  run wine python "/mnt/dedrm/DeDRM_tools-10.0.3/DeDRM_plugin/adobekey.py" 'Z:\mnt\adobekey_1.der'
}

extract_ade_library () {
  # Copy out any files from your library
  run rm -rf '/mnt/ade_library'
  run cp -r '/home/wineuser/My Digital Editions' '/mnt/ade_library'
}

# Debug shell
# shell; exit 1

prepare
install

# Boot up ADE. You should
# 1. Authorize your computer
# 2. Add in any of your `.acsm` files
# 3. Close the program when you are done
adobe_digital_editions

extract_ade_key
extract_ade_library
