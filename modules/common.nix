{
	inputs,
	pkgs,
	publicVars,
	...
}:
let
	userName = publicVars.user_short_name;
	userHome = "/home/${userName}";
in
{
	nixpkgs.config.allowUnfree = true;

	nix = {
		registry.nixpkgs.flake = inputs.nixpkgs;
		settings = {
			auto-optimise-store = true;
			experimental-features = [
				"nix-command"
				"flakes"
			];
		};
		gc = {
			automatic = true;
			dates = "weekly";
			options = "--delete-older-than 14d";
		};
	};

	boot = {
		loader = {
			systemd-boot.enable = true;
			timeout = 1;
		};
		initrd = {
			systemd.enable = true;
			luks.devices.cryptroot.device = "/dev/disk/by-partlabel/nixos-luks";
		};
		tmp.cleanOnBoot = true;
		kernel.sysctl = {
			"vm.swappiness" = 180;
			"vm.watermark_boost_factor" = 0;
			"vm.watermark_scale_factor" = 125;
			"vm.page-cluster" = 0;
		};
	};

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-label/nixos";
			fsType = "ext4";
			options = [ "noatime" ];
		};
		"/boot" = {
			device = "/dev/disk/by-label/BOOT";
			fsType = "vfat";
			options = [
				"fmask=0077"
				"dmask=0077"
			];
		};
	};

	zramSwap = {
		enable = true;
		memoryPercent = 100;
		priority = 100;
	};

	networking = {
		networkmanager.enable = true;
		firewall.enable = false;
	};

	time.timeZone = "America/Toronto";

	users = {
		users.${userName} = {
			isNormalUser = true;
			uid = 1000;
			description = publicVars.user_long_name;
			extraGroups = [
				"audio"
				"networkmanager"
				"podman"
				"video"
				"wheel"
			];
		};
	};

	security = {
		polkit.enable = true;
		rtkit.enable = true;
		sudo.wheelNeedsPassword = false;
	};

	services = {
		gvfs.enable = true;
		openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "no";
				PasswordAuthentication = false;
				KbdInteractiveAuthentication = false;
			};
		};
		pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
			pulse.enable = true;
		};
		printing.enable = true;
		tailscale = {
			enable = true;
			useRoutingFeatures = "both";
			extraSetFlags = [
				"--accept-routes"
				"--advertise-exit-node"
				"--exit-node="
			];
		};
		udisks2.enable = true;
		gnome.gnome-keyring.enable = true;
	};

	hardware = {
		bluetooth = {
			enable = true;
		};
		graphics = {
			enable = true;
			enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
		};
	};

	programs = {
		dconf.enable = true;
		niri.enable = true;
		nix-ld.enable = true;
	};

	xdg.portal = {
		enable = true;
		xdgOpenUsePortal = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
	};

	services.greetd = {
		enable = true;
		settings = {
			initial_session = {
				user = userName;
				command = "${pkgs.niri}/bin/niri-session";
			};
			default_session = {
				user = "greeter";
				command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd ${pkgs.niri}/bin/niri-session";
			};
		};
	};

	virtualisation.podman.enable = true;

	environment = {
		variables = {
			EDITOR = "nvi";
			NIXOS_OZONE_WL = "1";
			TERMINAL = "footclient";
		};
		etc."vimrc".source = inputs.infra-template + "/shared/vimrc";
		systemPackages = with pkgs; [
			bibata-cursors
			btop
			bubblewrap
			bun
			codex
			croc
			cryptsetup
			eza
			feishin
			file-roller
			git
			http-server
			imv
			jellyfin-desktop
			nautilus
			ncdu
			neovim
			nodejs
			pavucontrol
			ripgrep
			screen
			spotiflac
			unrar
			unzip
			uv
			vim
			vlc
			wl-clipboard
			xwayland-satellite
		];
	};

	services.locate.enable = true;

	fonts = {
		enableDefaultPackages = true;
		packages = with pkgs; [
			dejavu_fonts
			font-awesome
			jetbrains-mono
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

	systemd = {
		oomd = {
			enableRootSlice = true;
			enableSystemSlice = true;
			enableUserSlices = true;
		};
		tmpfiles.rules = [
			"d ${userHome}/.ssh 0700 ${userName} users - -"
			"d ${userHome}/.config/git 0700 ${userName} users - -"
		];
	};

	sops = {
		defaultSopsFile = ../secrets.yaml;
		age.keyFile = "/var/lib/sops-nix/key.txt";
		secrets = {
			ssh_public_key = {
				mode = "0444";
			};
			enc_priv_ssh_private_key = {
				owner = userName;
				group = "users";
				mode = "0600";
				path = "${userHome}/.ssh/id_ed25519";
			};
			enc_priv_git_credentials = {
				owner = userName;
				group = "users";
				mode = "0600";
				path = "${userHome}/.config/git/credentials";
			};
			enc_priv_croc_pass = {
				owner = userName;
				group = "users";
				mode = "0400";
			};
			enc_priv_croc_secret = {
				owner = userName;
				group = "users";
				mode = "0400";
			};
		};
	};

	services.openssh.authorizedKeysFiles = [ "/run/secrets/ssh_public_key" ];
}
