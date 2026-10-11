{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/2aa4894b-a2d7-43bb-9816-7c61ac7bd5ea";
      fsType = "btrfs";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/2aa4894b-a2d7-43bb-9816-7c61ac7bd5ea";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/2aa4894b-a2d7-43bb-9816-7c61ac7bd5ea";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0EBA-1E0C";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  
  fileSystems."/mnt/steam-games" = {
    device = "/dev/disk/by-uuid/af45af82-5f29-454f-9d18-f7e45fc132c0";
    fsType = "ext4";
    options = [
      "nofail"
      "exec"
      "x-gvfs-show"
    ];
  };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/246aa5f5-1664-40dd-a208-c1ccf4deaf0f"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
