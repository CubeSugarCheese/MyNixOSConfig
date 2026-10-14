{
  config,
  pkgs,
  inputs,
  ...
}:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
  };
in {
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];
  home.username = "cubic";
  home.homeDirectory = "/home/cubic";

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  home.packages = with pkgs; [
    # cli software
    fastfetch
    nix-weather
    p7zip
    yubikey-manager
    gnupg
    claude-code
    codex
    # gui software
    google-chrome
    wechat
    qq
    keyguard
    hmcl
    feishu
    libreoffice
    github-desktop
    motrix
    yubioath-flutter
    kdePackages.kcalc
    splayer-next
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
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-ceintl.vscode-language-pack-zh-hans

      # language support
      jnoortheen.nix-ide
      llvm-vs-code-extensions.vscode-clangd
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
      cache-default = 4000000;
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake $HOME/workbench/MyNixOSConfig";
    };
  };

  programs.codexDesktopLinux = {
    enable = true;
    linuxFeatures = [
      "read-aloud"
      "ui-tweaks"
    ];
  };

  home.stateVersion = "26.05"; # DO NOT MODIFY!
}
