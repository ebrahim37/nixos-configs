{
	homeFiles,
	osConfig,
	pkgs,
	publicVars,
	...
}:
let
	userName = publicVars.user_short_name;
in
{
	dconf.settings."org/gnome/desktop/interface" = {
		color-scheme = "prefer-dark";
	};

	home = {
		username = userName;
		homeDirectory = "/home/${userName}";
		stateVersion = osConfig.system.stateVersion;
		sessionPath = [ "$HOME/scripts" ];
		packages = with pkgs; [
			foot
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
			initExtra = ''
				PS1='\[\e[31m\][\[\e[33m\]\u\[\e[32m\]@\[\e[34m\]\h \[\e[35m\]\W\[\e[31m\]]\[\e[m\]\$ '
			'';
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
				settings = {
					"toolkit.legacyUserProfileCustomizations.stylesheets" = true;
				};
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
		noctalia = {
			enable = true;
			systemd.enable = true;
		};
	};

	systemd.user.startServices = "sd-switch";

	xdg = {
		enable = true;
		configFile."noctalia/config.toml".source = ../files/shared/noctalia-config.toml;
		configFile."niri/config.kdl".text = ''
			input {
				touchpad {
					tap
					natural-scroll
				}
			}

			layout {
				gaps 10
				focus-ring {
					off
				}
				border {
					width 2
					active-color "#89b4fa"
					inactive-color "#45475a"
				}
			}

			prefer-no-csd

			hotkey-overlay {
				skip-at-startup
			}

			screenshot-path "~/Downloads/Screenshot %Y-%m-%d %H-%M-%S.png"

			blur {
				passes 3
				offset 3
				saturation 1.17
			}

			window-rule {
				geometry-corner-radius 12
				clip-to-geometry true
			}

			window-rule {
				match app-id=r#"firefox$"# title="^Picture-in-Picture$"
				open-floating true
			}

			layer-rule {
				match namespace=r#"^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$"#
				background-effect {
					xray false
				}
			}

			binds {
				Mod+E { spawn "nautilus" "--new-window"; }
				Mod+B { spawn "firefox"; }
				Mod+Return { spawn "footclient"; }
				Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
				Mod+V { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
				Mod+F { fullscreen-window; }
				Mod+Q repeat=false { close-window; }
				Mod+L { spawn "noctalia" "msg" "session" "lock"; }
				Mod+S { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
				Mod+Comma { spawn "noctalia" "msg" "settings-toggle"; }
				Mod+Shift+E { quit; }

				Mod+Left { focus-column-left; }
				Mod+Right { focus-column-right; }
				Mod+Up { focus-window-up; }
				Mod+Down { focus-window-down; }
				Mod+Shift+Left { move-column-left; }
				Mod+Shift+Right { move-column-right; }
				Mod+Shift+Up { move-window-up; }
				Mod+Shift+Down { move-window-down; }

				Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
				Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }

				Mod+1 { focus-workspace 1; }
				Mod+2 { focus-workspace 2; }
				Mod+3 { focus-workspace 3; }
				Mod+4 { focus-workspace 4; }
				Mod+5 { focus-workspace 5; }
				Mod+6 { focus-workspace 6; }
				Mod+7 { focus-workspace 7; }
				Mod+8 { focus-workspace 8; }
				Mod+9 { focus-workspace 9; }
				Mod+Shift+1 { move-column-to-workspace 1; }
				Mod+Shift+2 { move-column-to-workspace 2; }
				Mod+Shift+3 { move-column-to-workspace 3; }
				Mod+Shift+4 { move-column-to-workspace 4; }
				Mod+Shift+5 { move-column-to-workspace 5; }
				Mod+Shift+6 { move-column-to-workspace 6; }
				Mod+Shift+7 { move-column-to-workspace 7; }
				Mod+Shift+8 { move-column-to-workspace 8; }
				Mod+Shift+9 { move-column-to-workspace 9; }

				Print { screenshot-screen; }
				Mod+Print { screenshot; }

				XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }
				XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }
				XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
				XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia" "msg" "brightness-up"; }
				XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia" "msg" "brightness-down"; }
				Alt+Tab repeat=false { spawn "noctalia" "msg" "window-switcher"; }
			}
		'';
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
