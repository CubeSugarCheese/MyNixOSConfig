# This function connects external dependencies to ordinary modules through a
# lexical closure. No specialArgs or Home Manager extraSpecialArgs are needed.
{
  home-manager,
  codex-desktop-linux,
  claude-desktop-nix-flake,
  llm-agents,
}:
{
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
        (import ./home.nix { inherit llm-agents; })
        codex-desktop-linux.homeManagerModules.default
      ];
    };
  };
}
