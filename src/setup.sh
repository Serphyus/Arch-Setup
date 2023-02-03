function show_logo {
	printf "\n\033[36m"
	printf "  ╔═════════════════════════════════════════════════════════════════════════════════╗\n"
	printf "  ║                                                                                 ║\n"
	printf "  ║   █████╗ ██████╗  ██████╗██╗  ██╗   ███████╗███████╗████████╗██╗   ██╗██████╗   ║\n"
	printf "  ║  ██╔══██╗██╔══██╗██╔════╝██║  ██║   ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗  ║\n"
	printf "  ║  ███████║██████╔╝██║     ███████║   ███████╗█████╗     ██║   ██║   ██║██████╔╝  ║\n"
	printf "  ║  ██╔══██║██╔══██╗██║     ██╔══██║   ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝   ║\n"
	printf "  ║  ██║  ██║██║  ██║╚██████╗██║  ██║   ███████║███████╗   ██║   ╚██████╔╝██║       ║\n"
	printf "  ║  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝       ║\n"
	printf "  ║                                                                                 ║\n"
	printf "  ╚═════════════════════════════════════════════════════════════════════════════════╝"
	printf "\033[0m\n\n"
}

# wrapper creates a loading effect
function exec_wrapper {
	{ eval "$1" > /dev/null 2>&1 & disown; pid=$!; } 3>&2 2>/dev/null
	printf "\033[?25l  [ ] $2 "
	i=0
	spin='-\|/'
	while kill -0 $pid 2>/dev/null; do
		i=$(( (i+1) %4 ))
		printf "\r  \033[33m[${spin:$i:1}"
		printf "]\033[0m"
		sleep .25
	done
	printf "\r  \033[32m[+]\033[0m\n\033[?25h"
}

function choose_install_disk {
	available=$(lsblk -d -o NAME,SIZE | tail +2)
	
	menu="whiptail
	--title 'Select Install Disk'
	--nocancel --menu '' 16 65 0"
	
	for line in $available; do
		menu="$menu '/dev/$line'"
	done

	menu="$menu 3>&1 1>&2 2>&3"
	eval $menu
}

function choose_encryption_key {
	main_msg="Choose encryption key:"
	while [[ "$encryption_key" != "$key_repeat" || ${#encryption_key} -lt 1 ]]; do
		encryption_key=$(eval "whiptail --nocancel --passwordbox '${main_msg}' 7 65 3>&1 1>&2 2>&3")
		key_repeat=$(eval "whiptail --nocancel --passwordbox 'Repeat encryption key:' 7 65 3>&1 1>&2 2>&3")
		main_msg="Encryption keys must match!"
	done

	echo $encryption_key
}

function choose_username {
	menu="whiptail
	--title 'Choose Account Username'
	--nocancel --inputbox '' 7 65"
	
	menu="$menu 3>&1 1>&2 2>&3"
	eval $menu
}

function choose_hostname {
	menu="whiptail
	--title 'Choose System Hostname'
	--nocancel --inputbox '' 7 65"
	
	menu="$menu 3>&1 1>&2 2>&3"
	eval $menu
}

function choose_password {
	main_msg="Choose password:"
	while [[ "$password" != "$key_repeat" || ${#password} -lt 1 ]]; do
		password=$(eval "whiptail --nocancel --passwordbox '${main_msg}' 7 65 3>&1 1>&2 2>&3")
		key_repeat=$(eval "whiptail --nocancel --passwordbox 'Repeat password:' 7 65 3>&1 1>&2 2>&3")
		main_msg="Passwords must match!"
	done

	echo $password
}

function confirm_choices {
	menu="whiptail --title \"User Confirmation\" --yesno \""
	for line in "$@"; do
		menu="$menu$line\n"
	done
	menu="$menu\" 7 65"
	if ! ( eval $menu ); then
		exit 0
	fi
}

function sync_repositories {
	pacman -Sy > /dev/null 2>&1
	reflector -c Norway -a 6 --sort rate --save /etc/pacman.d/mirrorlist
}

function partition_disk {
	parted $1 mklabel gpt
	parted $1 mkpart fat32 1MiB 301MiB set 1 esp on
	parted $1 mkpart ext4 301MiB 100%
}

function disk_setup {
	target_disk="$1"
	encryption_key="$2"
	
	exec_wrapper "wipefs -a $target_disk" "wiping old partitions"
	exec_wrapper "partition_disk $target_disk" "creating partitions"
	
	partitions=($(ls $target_disk))
	boot_partition="${partitions[1]}"
	root_partition="${partitions[2]}"
	luks_partition="/dev/mapper/cryptroot"
	
	exec_wrapper "echo -n "$encryption_key" | cryptsetup luksFormat $root_partition -" "encrypting root partition"
	exec_wrapper "echo -n "$encryption_key" | cryptsetup luksOpen $root_partition cryptroot -" "mounting encrypted partition"
	exec_wrapper "mkfs.fat -F32 -n BOOT $boot_partition; mkfs.ext4 $luks_partition" "formatting partitions"
	exec_wrapper "mount $luks_partition /mnt; mkdir /mnt/boot; mount $boot_partition /mnt/boot" "mounting partitions"
}

function pacstrap_packages {
	packages=$(cat $(dirname ${0})/packages | tr -s '\n' ' ')
	exec_wrapper "pacstrap /mnt $packages" "installing base packages"
}

function configure_system {
	current_dir=$(dirname ${0})
	
	cp $current_dir/config.sh /mnt/config.sh
	chmod +x $current_dir/config.sh
	
	arch-chroot /mnt /bin/bash -c "/config.sh \"${1}2\" \"$2\" \"$3\" \"$4\""
	
	rm -rf /mnt/config.sh
}

function main {
	if [ ! -z $(ping -c 1 google.com 2>&1 >/dev/null) ]; then
		printf "  \033[31m[!]\033[0m Unable to connect to internet\n"
	fi
	
	target_disk=$(choose_install_disk)
	encryption_key=$(choose_encryption_key)
	username=$(choose_username)
	hostname=$(choose_hostname)
	password=$(choose_password)

	confirm_choices "Install arch linux -> $target_disk"

	clear
	show_logo

	printf "  Installing System\n"
	printf "  ================================\n"

	exec_wrapper sync_repositories "syncing arch repos"
	disk_setup "$target_disk" "$encryption_key"
	pacstrap_packages
	exec_wrapper "genfstab -U /mnt >> /mnt/etc/fstab" "updating fstab"
	exec_wrapper "configure_system $target_disk $username $hostname $password" "running post install config"
}

main