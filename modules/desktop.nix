{
	pkgs,
	vars,
	...
}:
{
	security = {
		polkit.enable = true;
		rtkit.enable = true;
	};

	services = {
		gvfs.enable = true;
		pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
			pulse.enable = true;
		};
		printing.enable = true;
		udisks2.enable = true;
		gnome.gnome-keyring.enable = true;
		greetd = {
			enable = true;
			settings = {
				initial_session = {
					user = vars.user.username;
					command = "${pkgs.niri}/bin/niri-session";
				};
				default_session = {
					user = "greeter";
					command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd ${pkgs.niri}/bin/niri-session";
				};
			};
		};
	};

	hardware = {
		bluetooth.enable = true;
		graphics = {
			enable = true;
			enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
		};
	};

	programs = {
		dconf.enable = true;
		niri.enable = true;
	};

	xdg.portal = {
		enable = true;
		xdgOpenUsePortal = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
	};

	environment = {
		variables = {
			NIXOS_OZONE_WL = "1";
			TERMINAL = "footclient";
		};
		systemPackages = with pkgs; [
			bibata-cursors
			feishin
			file-roller
			imv
			nautilus
			pavucontrol
			(pkgs.callPackage ../packages/stremio-enhanced.nix { })
			vlc
			wl-clipboard
			xwayland-satellite
		];
	};

	fonts = {
		enableDefaultPackages = true;
		packages = with pkgs; [
			dejavu_fonts
			font-awesome
			nerd-fonts.jetbrains-mono
			noto-fonts
			noto-fonts-color-emoji
		];
		fontconfig.defaultFonts = {
			monospace = [ "JetBrainsMono Nerd Font" ];
			sansSerif = [ "Noto Sans" ];
			serif = [ "Noto Serif" ];
			emoji = [ "Noto Color Emoji" ];
		};
	};
}
