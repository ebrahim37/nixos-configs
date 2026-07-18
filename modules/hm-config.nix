{
	config,
	homeFiles,
	lib,
	osConfig,
	pkgs,
	publicVars,
	...
}:
let
	userName = publicVars.user_short_name;
in
{
	xdg.configFile."uwsm/env-hyprland".text = lib.optionalString
		(osConfig.networking.hostName == "pc-vmware") ''
		export AQ_NO_MODIFIERS=1
	'';

	home = {
		username = userName;
		homeDirectory = "/home/${userName}";
		stateVersion = osConfig.system.stateVersion;
		sessionPath = [ "$HOME/scripts" ];
		packages = with pkgs; [
			foot
			hyprlock
			hyprshot
		];

		file = {
			"scripts" = {
				source = homeFiles + "/scripts";
				recursive = true;
			};
			".config/nvim" = {
				source = homeFiles + "/.config/nvim";
				recursive = true;
			};
			".ssh/config".source = homeFiles + "/ssh_config";
		};
	};

	programs = {
		bash = {
			enable = true;
			shellAliases = {
				nvim = "nvi";
				sc = "systemctl --user";
				ssc = "sudo systemctl";
				jc = "journalctl --user -u";
				jjc = "journalctl -u";
			};
		};
		btop = {
			enable = true;
			settings = {
				theme_background = false;
				disable_presets = "Custom";
				shown_boxes = "mem cpu net proc";
				proc_gradient = false;
				cpu_graph_lower = "system";
				cpu_invert_lower = false;
				freq_mode = "range";
				swap_disk = false;
				swap_upload_download = true;
			};
		};
		firefox = {
			enable = true;
			profiles.${userName} = {
				id = 0;
				isDefault = true;
				settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
			};
		};
		foot = {
			enable = true;
			server.enable = true;
			settings = {
				main = {
					font = "JetBrainsMono Nerd Font:size=11";
					dpi-aware = "yes";
				};
				scrollback.lines = 10000;
				cursor.style = "beam";
			};
		};
		git = {
			enable = true;
			settings = {
				user = {
					name = publicVars.user_long_name;
					email = publicVars.git_email;
				};
				credential.helper = "store --file ~/.config/git/credentials";
				init.defaultBranch = "main";
				push.autoSetupRemote = true;
			};
		};
		home-manager.enable = true;
		hyprlock = {
			enable = true;
			settings = {
				general = {
					immediate_render = true;
				};
				background = [
					{
						color = "rgb(11111b)";
						blur_passes = 2;
					}
				];
				input-field = [
					{
						size = "300, 50";
						position = "0, -40";
						fade_on_empty = false;
						outline_thickness = 2;
						placeholder_text = "Password";
					}
				];
				label = [
					{
						text = "cmd[update:1000] date '+%H:%M'";
						font_family = "JetBrainsMono Nerd Font";
						font_size = 64;
						position = "0, 90";
					}
				];
			};
		};
		noctalia = {
			enable = true;
			settings = {
				shell = {
					launch_apps_as_systemd_services = true;
					font_family = "Noto Sans";
					launcher = {
						providers.session.global = true;
					};
				};
				theme = {
					builtin = "Noctalia";
				};
			};
		};
	};

	wayland.windowManager.hyprland = {
		enable = true;
		configType = "hyprlang";
		package = null;
		portalPackage = null;
		systemd.enable = false;
		settings = {
			"$mod" = "SUPER";
			monitor = [ ",preferred,auto,1" ];
			exec-once = [ "noctalia --daemon" ];

			input = {
				touchpad.natural_scroll = true;
			};

			cursor.no_hardware_cursors =
				if osConfig.networking.hostName == "pc-vmware" then 1 else 2;

			general = {
				gaps_out = 10;
				border_size = 2;
			};

			decoration = {
				rounding = 12;
				blur = {
					size = 3;
					passes = 2;
					vibrancy = 0.17;
				};
			};

			animations = {
				bezier = [ "easeOut,0.16,1,0.3,1" ];
				animation = [
					"windows,1,4,easeOut"
					"fade,1,4,easeOut"
					"workspaces,1,4,easeOut"
				];
			};

			dwindle = {
				preserve_split = true;
			};

			misc = {
				disable_hyprland_logo = true;
				disable_splash_rendering = true;
				force_default_wallpaper = 0;
			};

			bind = [
				"$mod, E, exec, uwsm app -- nautilus --new-window"
				"$mod, B, exec, uwsm app -- firefox"
				"$mod, RETURN, exec, uwsm app -- footclient"
				"$mod, SPACE, exec, noctalia msg panel-toggle launcher"
				"$mod, V, exec, noctalia msg panel-toggle clipboard"
				"$mod, F, fullscreen, 0"
				"$mod, Q, killactive"
				"$mod, L, exec, noctalia msg session lock"
				"$mod, S, exec, noctalia msg panel-toggle control-center"
				"$mod, COMMA, exec, noctalia msg settings-toggle"
				"$mod SHIFT, E, exit"
				"$mod, P, pseudo"
				"$mod, J, layoutmsg, togglesplit"
				"$mod, left, movefocus, l"
				"$mod, right, movefocus, r"
				"$mod, up, movefocus, u"
				"$mod, down, movefocus, d"
				"$mod SHIFT, left, movewindow, l"
				"$mod SHIFT, right, movewindow, r"
				"$mod SHIFT, up, movewindow, u"
				"$mod SHIFT, down, movewindow, d"
				"$mod, mouse_down, workspace, e+1"
				"$mod, mouse_up, workspace, e-1"
				", Print, exec, hyprshot -m output"
				"$mod, Print, exec, hyprshot -m region"
				", XF86AudioRaiseVolume, exec, noctalia msg volume-up"
				", XF86AudioLowerVolume, exec, noctalia msg volume-down"
				", XF86AudioMute, exec, noctalia msg volume-mute"
				", XF86MonBrightnessUp, exec, noctalia msg brightness-up"
				", XF86MonBrightnessDown, exec, noctalia msg brightness-down"
				"ALT, TAB, exec, noctalia msg window-switcher"
			]
			++ (builtins.concatLists (
				builtins.genList (
					i:
					let
						workspace = toString (i + 1);
					in
					[
						"$mod, ${workspace}, workspace, ${workspace}"
						"$mod SHIFT, ${workspace}, movetoworkspace, ${workspace}"
					]
				) 9
			));

			bindm = [
				"$mod, mouse:272, movewindow"
				"$mod, mouse:273, resizewindow"
			];

			layerrule = [
				"blur on, match:namespace ^(noctalia-(bar-.+|notification|dock|panel|attached-panel|osd))$"
				"ignore_alpha 0.5, match:namespace ^(noctalia-(bar-.+|notification|dock|panel|attached-panel|osd))$"
				"no_anim on, match:namespace ^(noctalia-(bar-.+|notification|dock|panel|attached-panel|osd))$"
			];

			windowrule = [
				"float on, match:class dev.noctalia.Noctalia"
				"size 1080 920, match:class dev.noctalia.Noctalia"
			];
		};
	};

	xdg = {
		enable = true;
		mimeApps = {
			enable = true;
			defaultApplications = {
				"audio/flac" = [ "vlc.desktop" ];
				"audio/mpeg" = [ "vlc.desktop" ];
				"audio/ogg" = [ "vlc.desktop" ];
				"audio/wav" = [ "vlc.desktop" ];

				"video/mp4" = [ "vlc.desktop" ];
				"video/mpeg" = [ "vlc.desktop" ];
				"video/webm" = [ "vlc.desktop" ];
				"video/x-matroska" = [ "vlc.desktop" ];
				"video/x-msvideo" = [ "vlc.desktop" ];

				"image/gif" = [ "imv.desktop" ];
				"image/jpeg" = [ "imv.desktop" ];
				"image/png" = [ "imv.desktop" ];
				"image/svg+xml" = [ "imv.desktop" ];
				"image/webp" = [ "imv.desktop" ];

				"inode/directory" = [ "org.gnome.Nautilus.desktop" ];

				"text/html" = [ "firefox.desktop" ];
				"x-scheme-handler/http" = [ "firefox.desktop" ];
				"x-scheme-handler/https" = [ "firefox.desktop" ];
			};
		};
	};
}
