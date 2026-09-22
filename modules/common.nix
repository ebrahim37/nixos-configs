{
	inputs,
	pkgs,
	vars,
	...
}:
let
	userName = vars.user.username;
in
{
	nixpkgs.config.allowUnfree = true;

	nix = {
		registry.nixpkgs.flake = inputs.nixpkgs;
		settings = {
			auto-optimise-store = true;
			experimental-features = [ "nix-command" "flakes" ];
			trusted-users = [ "root" userName ];
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
			options = [ "fmask=0077" "dmask=0077" ];
		};
	};

	zramSwap = {
		enable = true;
		memoryPercent = 100;
		priority = 100;
	};

	networking = {
		firewall.enable = false;
		networkmanager = {
			enable = true;
			dispatcherScripts = [
				{
					type = "basic";
					source = pkgs.writeShellScript "50-tailscale-udp-gro" ''
						if [ "$2" != "up" ]; then
							exit 0
						fi

						NETDEV="$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 | ${pkgs.coreutils}/bin/cut -f 5 -d " ")"
						"${pkgs.ethtool}/sbin/ethtool" -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
					'';
				}
			];
		};
	};

	time.timeZone = "America/Toronto";

	users.users.${userName} = {
		isNormalUser = true;
		uid = 1000;
		description = vars.user.name;
		extraGroups = [ "audio" "networkmanager" "podman" "video" "wheel" ];
		openssh.authorizedKeys.keys = [ vars.user.sshPublicKey ];
	};

	security.sudo = {
		wheelNeedsPassword = false;
		extraConfig = ''
			Defaults env_keep += "SYSTEMD_PAGER"
		'';
	};

	services = {
		openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "no";
				PasswordAuthentication = false;
				KbdInteractiveAuthentication = false;
				X11Forwarding = true;
			};
		};
		tailscale = {
			enable = true;
			useRoutingFeatures = "both";
			extraSetFlags = [
				"--accept-routes"
				"--advertise-exit-node"
				"--exit-node="
			];
		};
		locate.enable = true;
	};

	programs = {
		nix-ld.enable = true;
		ssh.setXAuthLocation = true;
	};

	virtualisation.podman.enable = true;

	environment = {
		variables = {
			EDITOR = "nvi";
			SYSTEMD_PAGER = "cat";
		};
		systemPackages = with pkgs; [
			age
			btop
			bubblewrap
			codex
			croc
			cryptsetup
			ethtool
			eza
			git
			http-server
			ncdu
			neovim
			nodejs
			omp
			pnpm
			ripgrep
			screen
			sops
			(vim-full.customize {
				name = "vim";
				vimrcConfig.customRC = builtins.readFile (inputs.infra-template + "/cnc-shared/vimrc");
			})
			unrar
			unzip
			uv
			waypipe
			xauth
		];
	};

	systemd = {
		oomd = {
			enableRootSlice = true;
			enableSystemSlice = true;
			enableUserSlices = true;
		};
		tmpfiles.rules = [
			"d /home/${userName}/.ssh 0700 ${userName} users - -"
			"d /home/${userName}/.config/git 0700 ${userName} users - -"
		];
	};

	sops = {
		defaultSopsFile = ../secrets.yaml;
		age.keyFile = "/var/lib/sops-nix/key.txt";
		secrets =
			let
				userSecret = mode: {
					inherit mode;
					owner = userName;
					group = "users";
				};
			in
			{
				enc_priv_ssh_private_key = userSecret "0400" // { path = "/home/${userName}/.ssh/id_ed25519"; };
				enc_priv_git_credentials = userSecret "0600" // { path = "/home/${userName}/.config/git/credentials"; };
				enc_priv_croc_pass = userSecret "0400";
				enc_priv_croc_secret = userSecret "0400";
				enc_priv_headscale_widget_token = userSecret "0400";
				enc_priv_discord_widget_token = userSecret "0400";
			};
	};
}
