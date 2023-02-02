<p align="center"><img src="logo.png"></p>
<h1 style="text-align: center">Arch-Setup - Arch linux installer</h1>

## Description
Arch-Setup is a simple arch linux installer to automate the reinstalling
process. The project is limited to EFI systems and encrypts the root
partition by default. The keyboard layout and localtime is also set to
Norway by default, however this can be changed in the `config.sh` file.

## Requirements
- EFI System
	- Due to the installer using bootctl as bootloader instead of grub the installer only supports EFI compatible systems

## Usage
```bash
git clone https://github.com/Serphyus/Arch-Setup.git
cd Arch-Setup
chmod +x src/*.sh
./src/setup.sh
```
