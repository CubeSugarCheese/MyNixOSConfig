{ config, pkgs, ... }:

{
  home.username = "cubic";
  home.homeDirectory = "/home/cubic";

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  home.packages = with pkgs;[
    # cli software
    fastfetch
    eza
    typst
    nixfmt
    nixd
    jdk21
    python314
    nodejs
    nix-weather
    p7zip
    yubikey-manager
    # gui software
    google-chrome
    netease-cloud-music-gtk
    wechat
    qq
    keyguard
    hmcl
    feishu
    libreoffice
    github-desktop
    motrix
    yubioath-flutter
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

      # misc
      editorconfig.editorconfig
    ];
  };

  programs.git = {
    enable = true;
    signing = {
      key = "${config.home.homeDirectory}/.ssh/catalycat.pub";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "catalycat";
        email = "me@catalycat.rs";
      };
      gpg = {
        format = "ssh";
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
    initExtra = ''

    '';
    shellAliases = {
      ls = "eza";
      rebuild = "sudo nixos-rebuild switch --flake $HOME/workbench/MyNixOSConfig";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
  };

  home.stateVersion = "26.05"; # DO NOT MODIFY!
}
