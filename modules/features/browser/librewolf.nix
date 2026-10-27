{ self, ... }:
{
  flake.nixosModules.librewolf =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.apertureLibrewolf
      ];
    };

  perSystem =
    { pkgs, lib, ... }:
    let
      bitwarden = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      nightTimeStars = "{d411c16f-6d54-4442-bea9-7ae36e9aaa22}";

      extensions = {
        "uBlock0@raymondhill.net" = "ublock-origin";
        ${bitwarden} = "bitwarden-password-manager";
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium-ff";
        "firefox-extension@steamdb.info" = "steam-database";
        "seventv-next@7tv.app" = "7tv-new";
        ${nightTimeStars} = "nighttime-stars-animated-theme";
      };

      toolbar = {
        placements = {
          widget-overflow-fixed-list = [ ];
          unified-extensions-area = [ ];
          nav-bar = [
            "back-button"
            "forward-button"
            "stop-reload-button"
            "customizableui-special-spring1"
            "vertical-spacer"
            "urlbar-container"
            "customizableui-special-spring2"
            "downloads-button"
            "fxa-toolbar-menu-button"
            "unified-extensions-button"
            "ublock0_raymondhill_net-browser-action"
            "firefox-extension_steamdb_info-browser-action"
            "reset-pbm-toolbar-button"
            "seventv-next_7tv_app-browser-action"
            "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
            "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action"
          ];
          toolbar-menubar = [ "menubar-items" ];
          TabsToolbar = [
            "tabbrowser-tabs"
            "new-tab-button"
            "customizableui-special-spring3"
            "alltabs-button"
          ];
          vertical-tabs = [ ];
          PersonalToolbar = [
            "sidebar-button"
            "personal-bookmarks"
          ];
        };
        currentVersion = 28;
      };

      prefs = {
        # ui
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.tabs.hoverPreview.showThumbnails" = false;
        "browser.settings-redesign.enabled" = false;
        "browser.theme.toolbar-theme" = 0;
        "browser.uiCustomization.state" = builtins.toJSON toolbar;
        "extensions.activeThemeID" = nightTimeStars;
        "sidebar.visibility" = "hide-on-close";
        "sidebar.main.tools" = "history,bookmarks,${bitwarden}";
        "findbar.highlightAll" = true;
        "layout.css.devPixelsPerPx" = "1.50";
        "layout.spellcheckDefault" = 0;
        "widget.gtk.hide-pointer-while-typing.enabled" = false;
        "dom.forms.autocomplete.formautofill" = true;
        "media.eme.enabled" = true;
        "devtools.toolbox.host" = "right";
        "devtools.toolbox.splitconsole.open" = true;

        # privacy
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.consentmanager.skip.pbmode.enabled" = false;
        "privacy.annotate_channels.strict_list.enabled" = true;
        "privacy.bounceTrackingProtection.mode" = 1;
        "privacy.query_stripping.enabled" = true;
        "privacy.query_stripping.enabled.pbmode" = true;
        "privacy.history.custom" = true;
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.clearOnShutdown_v2.cache" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearHistory.formdata" = true;

        # network
        "network.captive-portal-service.enabled" = false;
        "network.connectivity-service.enabled" = false;
        "captivedetect.canonicalURL" = "";
        "permissions.manager.defaultsUrl" = "";
        "network.predictor.enabled" = false;
        "network.prefetch-next" = false;
        "network.http.speculative-parallel-limit" = 0;
        "network.early-hints.preconnect.max_connections" = 0;
        "network.http.http3.enable_0rtt" = false;
        "security.tls.enable_0rtt_data" = false;
        "network.http.referer.XOriginPolicy" = 2;
        "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;
      };
    in
    {
      packages.apertureLibrewolf = pkgs.librewolf.override {
        extraPolicies = {
          ExtensionSettings = lib.mapAttrs (_: slug: {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
          }) extensions;

          SearchEngines = {
            Default = "Startpage";
            Remove = [
              "Google"
              "Bing"
              "Perplexity"
            ];
            Add = [
              {
                Name = "YouTube";
                URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
                IconURL = "https://www.youtube.com/favicon.ico";
              }
            ];
          };

          Handlers.schemes = lib.genAttrs [ "steam" "helpwire" "unityhub" ] (_: {
            action = "useSystemDefault";
            ask = false;
          });
        };

        extraPrefs = lib.concatLines (
          lib.mapAttrsToList (name: value: "pref(${builtins.toJSON name}, ${builtins.toJSON value});") prefs
        );
      };
    };
}
