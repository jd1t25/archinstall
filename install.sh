#!/bin/bash


#Pre-requesite

pre() {

		touch logs
		echo -e "\nPlease enter BOOT/EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
		read EFI

		echo -e "\nPlease enter SWAP paritition: (example /dev/sda2)"
		read SWAP

		echo -e "\nPlease enter Root(/) paritition: (example /dev/sda3)"
		read ROOT 

		echo -e "\nPlease enter Home(/) paritition: (example /dev/sda3)"
		read HOME 

		echo -e "\nPlease enter your username"
		read USER 

		echo -e "\nPlease enter your password"
		read PASSWORD

		echo -e "\n\n"

		echo "Boot/EFI: " $EFI
		echo -e "Swap: " $SWAP
		echo -e "Root: " $ROOT
		echo -e "Home: " $HOME
		echo -e "Username: " $USER
		echo -e "Password: " $PASSWORD
		echo -e "Correct(Y/N): "
		read OUTPUT
}

install() {

		mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
		mkswap "${SWAP}"
		swapon "${SWAP}"
		mkfs.ext4 -L "ROOT" "${ROOT}"
		mkfs.ext4 -L "HOME" "${HOME}"

		# mount target
		mount -t ext4 "${ROOT}" /mnt
		mkdir /mnt/boot
		mount -t vfat "${EFI}" /mnt/boot/
		mkdir /mnt/home
		mount -t ext4 "${HOME}" /mnt/home/

		# Main install
		pacstrap /mnt base base-devel --noconfirm --needed

		# kernel
		pacstrap /mnt sudo vim linux linux-firmware linux-headers --noconfirm --needed

		# fstab
		genfstab -U /mnt >> /mnt/etc/fstab

		# Grub
		grub

}

grub() {
		pacstap /mnt grub efibootmgr --noconfirm --needed
		mkdir /boot/efi
		mount $EFI /boot/efi
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
		grub-mkconfig -o /boot/grub/grub.cfg

		next
}


next() {
		
		arch-chroot /mnt

		useradd -m $USER
		usermod -aG wheel,storage,power,audio $USER
		echo $USER:$PASSWORD | chpasswd
		sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
		sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
		locale-gen
		echo "LANG=en_US.UTF-8" >> /etc/locale.conf
		ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
		hwclock --systohc
		echo "arch" > /etc/hostname
		cat <<EOF > /etc/hosts
		127.0.0.1	localhost
		::1			localhost
		127.0.1.1	arch.localdomain	arch
		EOF

		user
}

user() {

		mkdir  /home/$USER
		chown $USER:$USER /home/$USER
		echo $PASSWORD | sudo su - $USER

		pacman -S xorg pulseaudio stow git --noconfirm --needed
		systemctl enable NetworkManager bluetooth

		git clone https://github.com/jd1t25/dotfiles
		stow -d ~/dotfiles/ -t ~
		cd ~/dotfiles/config
		stow --adopt -t ~/.config .config


		install_packages
}



install_packages() {
		sudo pacman -Syu
		cat ~/dotfiles/backup/pacman.bak | xargs sudo pacman -S --noconfirm --needed 2> ~/packages.log

		yay
}

yay() {
  # Install yay
  sudo pacman -S --needed base-devel --noconfirm
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay

	foreign_packages
}

foreign_packages () {
  # Restore foreign packages
  cat ~/dotfiles/backup/yay.bak | xargs yay -S --needed --noconfirm 2> yay.log
}

#shloka
shloka () {
  var=$(cat ~/dotfiles/first_time/shloka.txt)
  for (( i=0; i<${#var}; i++ )); do
     sleep 0.03 | echo -ne "$(tput setaf 2)${var:$i:1}$(tput sgr 0)"
  done
  echo ""
}


main () {

		pre
		if [[ $OUTPUT == "N" || $OUTPUT == "n" ]]
		then
				pre
		fi

		# shloka &
		install &

}
