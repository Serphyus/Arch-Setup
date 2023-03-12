<p align="center"><img src="logo.png"></p>
<h1 align="center">Arch-Setup - Arch linux installer</h1>

## Description
Arch-Setup is a simple arch linux installer to automate the reinstalling
process. The project is limited to EFI systems and encrypts the root
partition by default. The keyboard layout and localtime is also set to
Norway by default, however this can be changed in the `config.sh` file.
The bootctl config will automatically boot into the arch system without
any prompt. This can be changed in the `/boot/loader/entries/arch.conf`.

## Requirements
- EFI Support
	- Due to the installer using bootctl as bootloader the system must have EFI support

## Usage
```bash
curl https://raw.githubusercontent.com/Serphyus/Arch-Setup/master/src/run.sh > run.sh
chmod +x run.sh
./run.sh
```
