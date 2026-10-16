# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;
  boot.loader.systemd-boot.configurationLimit = 10; # 防止 /boot 被旧内核塞满
  boot.consoleLogLevel = 2;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  # hostName 由 flake.nix 设置

  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  networking.firewall = {
    trustedInterfaces = [ "Mihomo" ];
    extraReversePathFilterRules = ''iifname { "Mihomo" } accept comment "trusted interface"'';
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  users.users."cubic" = {
    isNormalUser = true;
    description = "cubic";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.partition-manager.enable = true;

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  programs.steam = {
    enable = true;
    fontPackages = with pkgs; [
      noto-fonts-cjk-sans # 或 noto-fonts-cjk-serif
      wqy_zenhei # 文泉驿正黑，经典选择
    ];
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton-bin
    ];
  };

  programs.claude-desktop.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # 提供更快的缓存机制
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    kdePackages.kate
    wl-clipboard
    mission-center
  ];

  system.stateVersion = "26.05"; # DO NOT MODIFY!

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  fonts.packages = with pkgs; [
    adwaita-fonts
    noto-fonts-color-emoji
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans # 与思源黑体/宋体字形相同，无需重复安装 source-han-*
    noto-fonts-cjk-serif
    source-code-pro
    hack-font
    maple-mono.variable
    # windows fonts
    vista-fonts-chs
    corefonts
  ];

  # 简单配置一下 fontconfig 字体顺序，以免 fallback 到不想要的字体
  # 比如日文港台异体字
  fonts.fontconfig = {
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      # 等宽
      monospace = [
        "JetBrainsMono Nerd Font" # 字体名称请与你安装的包对应
        "DejaVu Sans Mono"
      ];
      # 无衬线
      sansSerif = [
        "Noto Sans CJK SC"
      ];
      # 衬线
      serif = [
        "Noto Serif CJK SC"
      ];
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true; # Use the open-source kernel module
    nvidiaSettings = true;
    # TODO(2026-10): temp fix for incompatible with linux 7.2
    # nixpkgs 修复后改回 config.boot.kernelPackages.nvidiaPackages.stable
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      # config.boot.kernelPackages.nvidiaPackages.stable;
      version = "595.99.02";
      sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
      sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
      openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
      settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
      persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
    };

    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  services.fwupd.enable = true;
  zramSwap.enable = true;

  # 透明压缩 + 减少写入；compress 只对新写入的数据生效
  fileSystems."/".options = [
    "compress=zstd"
    "noatime"
  ];
  fileSystems."/home".options = [
    "compress=zstd"
    "noatime"
  ];
  fileSystems."/nix".options = [
    "compress=zstd"
    "noatime"
  ];
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  # list all installed packages in /etc/current-system-packages
  environment.etc."current-system-packages".text =
    let
      packages = map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
