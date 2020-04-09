= Installation =

Ubuntu 18.04:
sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc zip

edit:
files/root/.ssh/klingler_measurements: should contain a ssh private key to be able to login on remote machine (e.g., 2nd APU)
files/root/.ssh/authorized_keys: corresponding ssh public key from above

optionally you want to also update: package/kernel/mac80211/files/regdb.txt
to allow custom requency bands supported by the wireless hardware: Keep in mind to respect legal regulations and restrictions!

Settings for the measurement framework:
files/root/measurements/_settings.sh

./scripts/feeds update -a
./scripts/feeds install -a
cp config.default .config
make defconfig
make -j4

Login to the APU Boxes as root.
invoke /root/tx.sh on the sender
invole /root/rx.sh on the receiver
