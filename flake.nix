{
  description = "My personal NixOS configuration";

  inputs = {
    # Plasma 6.7.5 retains the X11 session removed in Plasma 6.8.
    nixpkgs.url = "github:NixOS/nixpkgs/e7439b6b14ad3cc35d05608ebca9bce01a25f5f8";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop-nix-flake = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
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
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          ./nix-ld.nix

          home-manager.nixosModules.home-manager
          claude-desktop-nix-flake.nixosModules.default

          {
            nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.cubic = import ./home.nix;
            };
          }
        ];
      };
    };
}
