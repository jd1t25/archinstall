post() {

		arch-chroot /mnt su $USER <<-END
		pacman -S xorg pulseaudio stow git --noconfirm --needed

		git clone https://github.com/jd1t25/dotfiles
		stow -d ~/dotfiles/ -t ~
		cd ~/dotfiles/config
		stow --adopt -t ~/.config .config

		pacman -Sc --noconfirm
		sudo pacman -Syu yay
		cat ~/dotfiles/backup/pacman.bak | xargs sudo pacman -S --noconfirm --needed 2> ~/packages.log

		# Restore foreign packages
		cat ~/dotfiles/backup/yay.bak | xargs yay -S --needed --noconfirm 2> yay.log
		END
}

post 2>&1 | tee post.log
