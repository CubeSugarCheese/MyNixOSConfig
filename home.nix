{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # type: rustToolchain :: Derivation
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src"
      "rust-analyzer"
      "clippy"
      "rustfmt"
    ];
  };
  cliceExtension = pkgs.callPackage ./packages/clice.nix { };
  abDownloadManager = pkgs.callPackage ./packages/ab-download-manager.nix { };
  wpsOffice = pkgs.callPackage ./packages/wpsoffice.nix { };
  qqWaylandFix = pkgs.linuxqq-wayland-fix.overrideAttrs (old: {
    # Keep native pixels on HiDPI KDE outputs instead of upscaling a logical-size capture.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/qq-screenshot-helper.c \
        --replace-fail '"native-resolution", g_variant_new_boolean(FALSE)' \
                       '"native-resolution", g_variant_new_boolean(TRUE)'
    '';
  });
  qqWaylandCommand = "${qqWaylandFix}/bin/linuxqq-wayland-fix --enable-wayland-ime=true --wayland-text-input-version=3 %U";
in
{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];
  home.username = "cubic";
  home.homeDirectory = "/home/cubic";

  fonts.fontconfig.enable = true;
  # The store file is read-only; restore its link if a font manager replaces it.
  xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".force = true;

  # The Codex launcher reads these flags before choosing its default X11 backend.
  xdg.configFile."codex-desktop/electron-flags.conf".text = ''
    --ozone-platform=wayland
    --enable-wayland-ime=true
    --wayland-text-input-version=3
  '';

  # Keep the usual QQ menu entry, but launch it with the Wayland compatibility fixes.
  xdg.desktopEntries.qq = {
    name = "QQ";
    exec = qqWaylandCommand;
    icon = "${pkgs.qq}/share/icons/hicolor/512x512/apps/qq.png";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    settings.StartupWMClass = "QQ";
  };
  xdg.desktopEntries.linuxqq-wayland-fix = {
    name = "QQ (Wayland Fix)";
    exec = qqWaylandCommand;
    noDisplay = true;
  };

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
      Exec=${abDownloadManager}/bin/ab-download-manager --background
      Icon=ab-download-manager
      Terminal=false
      NoDisplay=true
    '';
  };

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
    qqWaylandFix
    keyguard
    hmcl
    feishu
    github-desktop
    abDownloadManager
    yubioath-flutter
    kdePackages.kcalc
    splayer-next
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh
    wpsOffice
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
      cliceExtension
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
      # 启用 wayland
      mpv-unwrapped = pkgs.mpv-unwrapped.override {
        waylandSupport = true;
      };
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
