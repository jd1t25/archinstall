user() {

		arch-chroot /mnt su $USER <<-END
		pacman -S xorg pulseaudio stow git go --noconfirm --needed
		systemctl enable NetworkManager bluetooth

		git clone https://github.com/jd1t25/dotfiles
		stow -d ~/dotfiles/ -t ~
		cd ~/dotfiles/config
		stow --adopt -t ~/.config .config

		pacman -Sc --noconfirm
		sudo pacman -Syu
		cat ~/dotfiles/backup/pacman.bak | xargs sudo pacman -S --noconfirm --needed 2> ~/packages.log


		# Install yay
		sudo pacman -S --needed base-devel --noconfirm
		git clone https://aur.archlinux.org/yay.git
		cd yay
		makepkg -si
		cd ..
		rm -rf yay
		
		# Restore foreign packages
		cat ~/dotfiles/backup/yay.bak | xargs yay -S --needed --noconfirm 2> yay.log
		END
}

user 2>&1 | tee user.log
