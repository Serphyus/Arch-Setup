function sync_repositories {
	pacman -Sy
	reflector -c Norway -a 6 --sort rate --save /etc/pacman.d/mirrorlist
}

function sync_localtime {
	timedatectl set-ntp true
	ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
	hwclock --systohc
}

function generate_locale {
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	echo "en_US ISO-8859-1" >> /etc/locale.gen
	locale-gen
}

function setup_keymap {
	echo "KEYMAP=no" >> /etc/vconsole.conf
}

function setup_hostname {
	hostname="$1"
	echo "$hostname" > /etc/hostname
	echo "127.0.0.1	localhost"                         >  /etc/hosts
	echo "::1		localhost"                         >> /etc/hosts
	echo "127.0.1.1	$hostname.localdomain	$hostname" >> /etc/hosts
}

function setup_users {
	username="$1"
	password="$2"

	useradd -mG wheel $username
	echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

	echo -e "$password\n$password" | passwd
	echo -e "$password\n$password" | passwd $username
}

function setup_mkinitcpio {
	sed -i "s/HOOKS=(.*/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/" /etc/mkinitcpio.conf
	mkinitcpio -p linux
}

function setup_bootloader {
	bootctl --path=/boot install

	echo "default arch" > /boot/loader/loader.conf
	echo "editor 0" >> /boot/loader/loader.conf
	
	echo "title Arch Linux" > /boot/loader/entries/arch.conf
	echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	echo "options cryptdevice=$1:cryptroot root=/dev/mapper/cryptroot quiet rw" >> /boot/loader/entries/arch.conf
}

function enable_services {
	systemctl enable NetworkManager
	systemctl enable bluetooth
	systemctl enable cups.service
	systemctl enable avahi-daemon
	systemctl enable tlp
	systemctl enable acpid
	systemctl enable reflector.timer
	systemctl enable fstrim.timer
	systemctl enable libvirtd
	systemctl enable firewalld
}

function disable_bios_sound {
    echo "blacklist pcspkr" | tee -a /etc/modprobe.d/blacklist.conf
}

root_partition="$1"
username="$2"
hostname="$3"
password="$4"

sync_repositories
sync_localtime
generate_locale
setup_keymap
setup_hostname $hostname
setup_users $username $password
install_packages
setup_mkinitcpio
setup_bootloader $root_partition
enable_services
disable_bios_sound