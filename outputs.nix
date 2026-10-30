{
  nixpkgs,
  rust-overlay,
  home-manager,
  claude-desktop-nix-flake,
  codex-desktop-linux,
  ...
}@inputs:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      rust-overlay.overlays.default
      import ./overlays/cinnamon.nix
      import ./overlays/gpaste.nix
    ];
  };
  localPkgs = pkgs.callPackage ./packages { };
in
{
  formatter.x86_64-linux = pkgs.nixfmt-tree;

  packages.x86_64-linux = {
    inherit (localPkgs)
      ab-download-manager
      clice
      personal-fonts
      plangothic
      wpsoffice
      ;
  };

  nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
    modules = [
      {
        nixpkgs.pkgs = pkgs;
        imports = [
          ./configuration.nix
          ./hardware-configuration.nix
          ./nix-ld.nix
          home-manager.nixosModules.home-manager
          claude-desktop-nix-flake.nixosModules.default
        ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.cubic = {
            imports = [
              (import ./home.nix inputs)
              codex-desktop-linux.homeManagerModules.default
            ];
          };
        };
      }
    ];
  };
}
