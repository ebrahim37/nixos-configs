// open every new tab immediately to the right of the active tab
user_pref("browser.tabs.insertAfterCurrent", true);

// keep the pointer visible while typing on every desktop platform
user_pref("ui.hideCursorWhileTyping", 0);

// enable middle-click autoscrolling (including on Linux, where it is off by default) 
user_pref("general.autoScroll", true);
// do not use middle-click as primary-selection paste
user_pref("middlemouse.paste", false);

// remove the sidebar chatbot and prevent Firefox from enabling it remotely
user_pref("browser.ai.control.sidebarChatbot", "blocked");
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.page", false);
user_pref("browser.ml.chat.sidebar", false);

user_pref("browser.uidensity", 1);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"vertical-spacer\",\"home-button\",\"urlbar-container\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"firefox_tampermonkey_net-browser-action\",\"librezam_librezam-browser-action\",\"_b9db16a4-6edc-47ec-a1f4-b86292ed211d_-browser-action\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"unified-extensions-button\",\"reset-pbm-toolbar-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"ai-window-toggle\",\"smartwindow-group-tabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"personal-bookmarks\",\"bookmarks-menu-button\"]},\"seen\":[\"developer-button\",\"profiler-button\",\"screenshot-button\",\"ublock0_raymondhill_net-browser-action\",\"firefox_tampermonkey_net-browser-action\",\"librezam_librezam-browser-action\",\"_b9db16a4-6edc-47ec-a1f4-b86292ed211d_-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"reset-pbm-toolbar-button\",\"ai-window-toggle\",\"smartwindow-group-tabs-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"toolbar-menubar\",\"TabsToolbar\",\"unified-extensions-area\"],\"currentVersion\":26,\"newElementCount\":9}");
