{
	config,
	homeFiles,
	inputs,
	pkgs,
	...
}:
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
			efi.canTouchEfiVariables = true;
			timeout = 1;
		};
		initrd = {
			systemd.enable = true;
			luks.devices.cryptroot = {
				device = "/dev/disk/by-partlabel/nixos-luks";
				crypttabExtraOpts = [
					"tpm2-device=auto"
					"tpm2-pcrs=7"
				];
			};
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
		users.ebrahim = {
			isNormalUser = true;
			uid = 1000;
			description = "Ebrahim";
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
		tpm2 = {
			enable = true;
			pkcs11.enable = true;
			tctiEnvironment.enable = true;
		};
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
		tailscale.enable = true;
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
		firefox = {
			enable = true;
			policies.ExtensionSettings = {
				"uBlock0@raymondhill.net" = {
					installation_mode = "normal_installed";
					install_url = "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi";
				};
				"{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
					installation_mode = "normal_installed";
					install_url = "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi";
				};
			};
		};
		hyprland = {
			enable = true;
			withUWSM = true;
			xwayland.enable = true;
		};
		nix-ld.enable = true;
	};

	xdg.portal = {
		enable = true;
		xdgOpenUsePortal = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
		config.common.default = [
			"hyprland"
			"gtk"
		];
	};

	services.greetd = {
		enable = true;
		settings.default_session = {
			user = "greeter";
			command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd '${pkgs.uwsm}/bin/uwsm start -- hyprland-uwsm.desktop'";
		};
	};

	virtualisation.podman.enable = true;

	environment = {
		variables = {
			EDITOR = "nvi";
			NIXOS_OZONE_WL = "1";
			TERMINAL = "footclient";
		};
		etc."vimrc".source = homeFiles + "/vimrc";
		systemPackages = with pkgs; [
			btop
			bubblewrap
			bun
			codex
			croc
			cryptsetup
			eza
			feishin
			file-roller
			firefox
			git
			http-server
			imv
			nautilus
			ncdu
			neovim
			nodejs
			pavucontrol
			ripgrep
			screen
			spotiflac
			unrar
			uv
			vim
			vlc
			wl-clipboard
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
	};

	sops = {
		defaultSopsFile = ../secrets.yaml;
		age.keyFile = "/var/lib/sops-nix/key.txt";
		secrets = {
			ssh_public_key = {
				mode = "0444";
			};
			enc_priv_ssh_private_key = {
				owner = "ebrahim";
				group = "users";
				mode = "0600";
				path = "/home/ebrahim/.ssh/id_ed25519";
			};
			env_priv_git_credentials = {
				owner = "ebrahim";
				group = "users";
				mode = "0600";
				path = "/home/ebrahim/.config/git/credentials";
			};
			enc_priv_croc_pass = {
				owner = "ebrahim";
				group = "users";
				mode = "0400";
			};
			enc_priv_croc_secret = {
				owner = "ebrahim";
				group = "users";
				mode = "0400";
			};
		};
	};

	services.openssh.authorizedKeysFiles = [
		"/run/secrets/ssh_public_key"
	];
}
