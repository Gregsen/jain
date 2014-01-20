#!/bin/bash

# Version 0.1
# author  Gregsen
# email gkneitschel @at gmail .dot com

JAVA_INSTALL_DIR="/opt/Oracle_Java/"
FILE="java.tar.gz"  # name of the file after download


# make sure you are running this as root
if [ "$(id -u)" != 0 ]; then
	echo "You need to be root. Try running this script with sudo!"
	exit 1
fi

# getting wget for downloading and dialog for gui
echo "preparing environment..."
if command -v apt-get &>/dev/null; then
    sudo apt-get install -y wget dialog
else
    echo "error can't install packages wget and dialog!"
    exit 1;
fi

dialog  --backtitle "Gregsen installs JAVA" \
        --title "JAVA INSTALLER" \
        --inputbox "Please provide an URI for downloading Java\n (leave empty for 7u45 as default)" 8 40 \
        2>/tmp/dialog.ans
URL=$(cat /tmp/dialog.ans)

if [[ ! -s  /tmp/dialog.ans ]]; then
    # show progress as dotted lines
    url="http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.tar.gz"
    wget --progress=dot --no-check-certificate --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "$url" -O "$FILE" 2>&1 |
    grep "%" |              # print only line that contain %
    sed -u -e "s,\.,,g" |   # remove dots
    awk '{print $2}' |      # print second column
    sed -u -e "s,\%,,g"  |  # remove percentage sign
    dialog --gauge "Downloading Java" 10 100
else
    wget --progress=dot --no-check-certificate --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "$URL" -O "$FILE" 2>&1 |
    grep "%" |
    sed -u -e "s,\.,,g" |
    awk '{print $2}' |
    sed -u -e "s,\%,,g"  |
    dialog --gauge "Download Java" 10 100
fi

# This function accepts a message and a a number. Both will update the progressbar
progress (){
msg=$1
prgs=$2

cat <<EOF
XXX
$prgs
$msg
XXX
EOF
}

{
while :
do
# check the archive
#TODO If the archive is corrupt, this part will not exit gracefully. make better
progress "verify archive integrity" 16
gunzip -c "$FILE" | tar -t > /dev/null
STATUS=$?
if [ $STATUS -ne 0 ]; then
	dialog  --backtitle "Gregsen installs JAVA" \
    --infobox "Archive corrupted" 10 30
    exit 1
fi

# find install dir or make it
progress "checking installation directory (/opt/Oracle_Java/)" 32
if [ ! -d "$JAVA_INSTALL_DIR" ]; then
	progress "Directory not found. Creating..." 34
	sudo mkdir /opt/Oracle_Java
else
    progress "Directory found" 34
fi

# extracting
progress "Extractig files" 60
JAVA_DIR=$(sudo tar -xvzf "$FILE" -C "$JAVA_INSTALL_DIR" | sed -e 's@/.*@@' | uniq)

# update alternatives
progress "Installing alternatives" 75
sudo update-alternatives --install "/usr/bin/java" "java" "$JAVA_INSTALL_DIR$JAVA_DIR/bin/java" 1
sudo update-alternatives --install "/usr/bin/javaws" "javaws" "$JAVA_INSTALL_DIR$JAVA_DIR/bin/javaws" 1

#echo "Updating alternatives"
progress "Updating alternatives" 85
sudo update-alternatives --set "java" "$JAVA_INSTALL_DIR$JAVA_DIR/bin/java"
sudo update-alternatives --set "javaws" "$JAVA_INSTALL_DIR$JAVA_DIR/bin/javaws"

# finish. Export PATH
progress "Set JAVA_HOME" 90
echo "export JAVA_HOME=$JAVA_INSTALL_DIR$JAVA_DIR" >> ~/.bash_profile
echo "export PATH=$PATH:$JAVA_HOME/bin" >> ~/.bash_profile


progress "Refresh .bash_profile" 100
. ~/.bash_profile

break
done
} | dialog  --backtitle "Gregsen installs JAVA" --title "Installation progress" --gauge 30 10 0

dialog  --backtitle "Gregsen installs JAVA" \
        --title "Installation progress" \
        --infobox "java has been successfully installed" 10 30

