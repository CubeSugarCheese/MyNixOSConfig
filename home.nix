{ llm-agents }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  localPkgs = pkgs.callPackage ./packages { };

  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src"
      "rust-analyzer"
      "clippy"
      "rustfmt"
    ];
  };
in
{
  home.username = "cubic";
  home.homeDirectory = "/home/cubic";

  fonts.fontconfig.enable = true;
  # The store file is read-only; restore its link if a font manager replaces it.
  xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".force = true;

  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "menu/page_size": 9
  '';

  # Default to simplified Chinese when entering either pinyin schema.
  xdg.dataFile."fcitx5/rime/luna_pinyin.custom.yaml".text = ''
    patch:
      "switches/@2/reset": 1
  '';
  xdg.dataFile."fcitx5/rime/terra_pinyin.custom.yaml".text = ''
    patch:
      "switches/@2/reset": 1
  '';

  # Keep a separate name from the mutable autostart item written by the app.
  # The app's own "start on boot" setting should remain disabled.
  xdg.configFile."autostart/ab-download-manager.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=AB Download Manager
      Exec=${localPkgs.ab-download-manager}/bin/ab-download-manager --background
      Icon=ab-download-manager
      Terminal=false
      NoDisplay=true
    '';
  };

  # Variety rewrites its preferences and autostart entry, so seed writable
  # files once rather than linking them to read-only Nix store files.
  home.activation.initVariety =
    let
      initialConfig = pkgs.writeText "variety.conf" ''
        change_on_start = True
        change_enabled = True
        change_interval = 86400
        internet_enabled = True
        wallpaper_display_mode = gnome-zoom
        quota_enabled = True
        quota_size = 500
        clock_enabled = False
        quotes_enabled = False
        smart_enabled = False
        sync_enabled = False
        stats_enabled = False

        [sources]
        src1 = True|bing|https://www.bing.com/gallery/
        src2 = False|favorites|The Favorites folder
        src3 = False|fetched|The Fetched folder
      '';
      autostartEntry = pkgs.writeText "variety.desktop" ''
        [Desktop Entry]
        Type=Application
        Name=Variety
        Exec=${pkgs.variety}/bin/variety
        Icon=variety
        Terminal=false
        X-GNOME-Autostart-Delay=10
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${config.xdg.configHome}/variety/variety.conf" ]; then
        run ${pkgs.coreutils}/bin/install -Dm644 ${initialConfig} \
          "${config.xdg.configHome}/variety/variety.conf"
      fi
      if [ ! -e "${config.xdg.configHome}/autostart/variety.desktop" ]; then
        run ${pkgs.coreutils}/bin/install -Dm644 ${autostartEntry} \
          "${config.xdg.configHome}/autostart/variety.desktop"
      fi
    '';

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  home.packages = with pkgs; [
    # cli software
    fastfetch
    ripgrep
    nix-weather
    p7zip
    yubikey-manager
    gnupg
    claude-code
    codex
    android-tools
    # gui software
    google-chrome
    wechat
    qq
    keyguard
    hmcl
    feishu
    github-desktop
    yubioath-flutter
    splayer-next
    variety
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh
    localPkgs.ab-download-manager
    localPkgs.wpsoffice
    # language enviroment
    ## nix
    nixd
    nixfmt
    ## java
    jdk25
    ## python
    python314
    ## typst
    typst
    ## javascript
    nodejs_latest
    ## go
    go
    gopls
    delve
    ## rust
    rustToolchain
  ];

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-ceintl.vscode-language-pack-zh-hans

      # language support
      jnoortheen.nix-ide
      localPkgs.clice
      tamasfe.even-better-toml
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      charliermarsh.ruff
      rust-lang.rust-analyzer
      myriad-dreamin.tinymist
      golang.go

      # misc
      editorconfig.editorconfig
    ];
  };

  programs.git = {
    enable = true;
    signing = {
      key = "E5B4A6DF824508E68D05F163453509314E993365";
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      user = {
        name = "catalycat";
        email = "me@catalycat.rs";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/catalycat";
      IPQoS = "none";
    };

    settings."github.com" = {
      hostname = "ssh.github.com";
      user = "git";
      port = 443;
      identityFile = "~/.ssh/catalycat";
      identitiesOnly = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
  };

  home.sessionVariables = {
    EDITOR = "code --wait";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  };

  # 自带 ls/ll/la/lt 等别名
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  programs.starship = {
    enable = true;
    # 自定义配置
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  programs.mpv = {
    enable = true;
    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [
        uosc
        sponsorblock
      ];
    };
    # mpv 自身配置
    config = {
      profile = "high-quality";
      ytdl-format = "bestvideo+bestaudio";
    };
  };

  programs.codexDesktopLinux = {
    enable = true;
    linuxFeatures = [
      "read-aloud"
      "ui-tweaks"
    ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      rebuild = ''(cd "${config.programs.nh.flake}" && nix fmt && nh os switch .)'';
    };
  };

  programs.nh = {
    enable = true;
    flake = "/home/cubic/workbench/MyNixOSConfig";

    clean = {
      enable = true;
      extraArgs = "--keep-since 4d --keep 3";
    };
  };

  home.stateVersion = "26.05"; # DO NOT MODIFY!
}
