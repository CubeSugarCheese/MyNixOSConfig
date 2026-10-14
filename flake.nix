{
  description = "My personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # github:NixOS/nixpkgs/nixos-26.05

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
    claude-desktop-nix-flake.url = "github:poeck/claude-desktop-nix-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      claude-desktop-nix-flake,
      ...
    }@inputs:
    {
      nixosConfigurations = nixpkgs.lib.genAttrs [ "nixos" ] (
        hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            { networking.hostName = hostName; }
            ./configuration.nix
            ./hardware-configuration.nix
            ./nix-ld.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.cubic = import ./home.nix;
            }
            claude-desktop-nix-flake.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              programs.claude-desktop.enable = true;
            }
          ];
        }
      );
    };
}
