#!/bin/bash
# in MacOS /usr/share is prohibited for sudo commands by SIP (system integrity protection), need to move somewhere else - /usr/local is still available
INSTALL_FOLDER=/usr/local/ad2

echo "Creating folder ad2"
sudo mkdir ${INSTALL_FOLDER}
#echo "Downloading acarsdeco2 file from Google Drive"
#sudo wget -O ${INSTALL_FOLDER}/acarsdeco2_rpi2-3_debian9_20181201.tgz "https://drive.google.com/uc?export=download&id=1n0nWk-VRqj-Zamm29-DVYG8eQ8tVdv82"
echo "Downloading acarsdeco2 file from Github"
sudo wget -O ${INSTALL_FOLDER}/acarsdeco2_rpi2-3_debian9_20181201.tgz "https://github.com/abcd567a/ad2/releases/download/V1/acarsdeco2_rpi2-3_debian9_20181201.tgz"

# for unziping tar is obviously necessary - look for it with 'brew search gnu-tar' or 'port search gnutar'
echo "Unzipping downloaded file"
sudo tar xvzf ${INSTALL_FOLDER}/acarsdeco2_rpi2-3_debian9_20181201.tgz -C ${INSTALL_FOLDER}

# in Macos usr/bin access is restricted by SIP - moving to home directory 
echo "Creating symlink to acarsdeco2 binary in folder ~/bin/ "
sudo mkdir ~/bin
sudo ln -s ${INSTALL_FOLDER}/acarsdeco2  ~/bin/acarsdeco2

echo "Creating startup script file ad2-start.sh"
SCRIPT_FILE=${INSTALL_FOLDER}/ad2-start.sh
sudo touch ${SCRIPT_FILE}
sudo chmod 777 ${SCRIPT_FILE}
echo "Writing code to startup script file ad2-start.sh"
/bin/cat <<EOM >${SCRIPT_FILE}
#!/bin/sh
CONFIG=""
while read -r line; do CONFIG="\${CONFIG} \$line"; done < ${INSTALL_FOLDER}/ad2.conf
${INSTALL_FOLDER}/acarsdeco2 \${CONFIG}
EOM
sudo chmod +x ${SCRIPT_FILE}

echo "Creating config file mm2.conf"
CONFIG_FILE=${INSTALL_FOLDER}/ad2.conf
sudo touch ${CONFIG_FILE}
sudo chmod 777 ${CONFIG_FILE}
echo "Writing code to config file ad2.conf"
/bin/cat <<EOM >${CONFIG_FILE}
--freq 131550000
--freq 131725000
--http-port 8686
EOM
sudo chmod 644 ${CONFIG_FILE}

echo "Creating Service file ad2.service"
# SERVICE_FILE=/lib/systemd/system/ad2.service in MacOS this doesn't work try maintain launchd instead
SERVICE_FILE=~/Library/LaunchAgents/service.ad2.plist
sudo touch ${SERVICE_FILE}
sudo chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# acarsdeco2 service for systemd - replace the following lines with launchd syntax 
# [Unit]
# Description=AcarSDeco2
# Wants=network.target
# After=network.target
# [Service]
# RuntimeDirectory=acarsdeco2
# RuntimeDirectoryMode=0755
# ExecStart=/bin/bash ${INSTALL_FOLDER}/ad2-start.sh
# SyslogIdentifier=acarsdeco2
# Type=simple
# Restart=on-failure
# RestartSec=30
# RestartPreventExitStatus=64
# Nice=-5
# [Install]
# WantedBy=default.target
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>service.ad2</string>
    <key>Program</key>
    <string>acarsdeco2</string>
    <key>ProgramArguments</key>
    <array>             
        <string>/bin/bash ${INSTALL_FOLDER}/ad2-start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>Nice</key>
    <integer>-5</integer>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist> 
EOM
sudo chmod 644 ${SERVICE_FILE}
# sudo systemctl enable ad2
sudo launchctl load ${SERVICE_FILE}

# the following lines don't make sense in MacOS
# echo "Creating blacklist-rtl-sdr file..."
# BLACKLIST_FILE=/etc/modprobe.d/blacklist-rtl-sdr.conf
# sudo touch ${BLACKLIST_FILE}
# sudo chmod 777 ${BLACKLIST_FILE}
# echo "Writing code to blacklist file"
# /bin/cat <<EOM >${BLACKLIST_FILE}
# blacklist rtl2832
# blacklist dvb_usb_rtl28xxu
# blacklist dvb_usb_v2,rtl2832
# EOM
# sudo chmod 644 ${BLACKLIST_FILE}

# echo "Unloading kernel drivers for rtl-sdr..."
# sudo rmmod rtl2832 dvb_usb_rtl28xxu dvb_usb_v2,rtl2832

echo "Starting  AcarSDeco2 ..."
# sudo systemctl start ad2
sudo launchctl start service.ad2

echo ''
echo ''
echo 'INSTALLATION COMPLETED'
echo '======================'
echo ' PLEASE DO FOLLOWING. '
echo '======================'
echo 'In your browser, go to web interface at'
echo 'http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8686'
echo ''
echo 'To view/edit configuration, open config file by following command'
echo '                           sudo nano "${INSTALL_FOLDER}"/ad2.conf '
echo ''
echo '  (a) Default value of gain is auto'
echo '      To use another value of gain, add following NEW LINE'
echo '      (replace xx by desired value of gain)'
echo '    --gain xx'
echo '  (b) Default value of frequency correction is 0'
echo '      To use a different value, add following NEW LINE'
echo '      (replace xx by desired frequency correction in PPM)'
echo '    --freq-correction xx '
echo ''
echo 'Save (Ctrl+o) and Close (Ctrl+x) the file'
echo 'then restart ad2 by following command:'
echo '                            sudo launchctl restart service.ad2 '
echo ''
echo 'To see status:              sudo launchctl status service.ad2'
echo 'To restart:                 sudo launchctl restart service.ad2'
echo 'To stop:                    sudo launchctl stop service.ad2'


