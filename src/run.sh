TMP_DIR="/tmp/arch_setup/"

mkdir $TMP_DIR
cd $TMP_DIR

curl https://raw.githubusercontent.com/Serphyus/Arch-Setup/master/src/setup.sh -o setup.sh
curl https://raw.githubusercontent.com/Serphyus/Arch-Setup/master/src/config.sh -o config.sh
curl https://raw.githubusercontent.com/Serphyus/Arch-Setup/master/src/packages -o packages

chmod +x $TMP_DIR/*.sh

$TMP_DIR/setup.sh
rm -rf $TMP_DIR