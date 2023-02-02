function sync_repositories {
	pacman -Syu > /dev/null 2>&1
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

	echo -e "$password\n$password" | passwd           > /dev/null 2>&1
	echo -e "$password\n$password" | passwd $username > /dev/null 2>&1
}

function setup_mkinitcpio {
	sed -i "s/HOOKS=(.*/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/" /etc/mkinitcpio.conf
	mkinitcpio -p linux > /dev/null 2>&1
}

function setup_bootloader {
	root_uuid=$(blkid -o value -s UUID $1)

	bootctl --path=/boot install

	echo "default arch" > /boot/loader/loader.conf
	echo "editor 0" >> /boot/loader/loader.conf
	
	echo "title Arch Linux" > /boot/loader/entries/arch.conf
	echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
	echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
	echo "options cryptdevice=UUID=$root_uuid:cryptroot root=/dev/mapper/cryptroot quiet rw" >> /boot/loader/entries/arch.conf
}

function enable_services {
	systemctl enable NetworkManager     > /dev/null 2>&1
	systemctl enable bluetooth          > /dev/null 2>&1
	systemctl enable cups.service       > /dev/null 2>&1
	systemctl enable avahi-daemon       > /dev/null 2>&1
	systemctl enable tlp                > /dev/null 2>&1
	systemctl enable acpid              > /dev/null 2>&1
	systemctl enable reflector.timer    > /dev/null 2>&1
	systemctl enable fstrim.timer       > /dev/null 2>&1
	systemctl enable libvirtd           > /dev/null 2>&1
	systemctl enable firewalld          > /dev/null 2>&1
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