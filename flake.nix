{
  description = "NixOS module hosting a Radilce seed node.";
  inputs = {
    flake-compat.url = "https://github.com/9999years/flake-compat/archive/refs/heads/fix-64.tar.gz";
    nixpkgs.url = "github:NixOS/nixpkgs";

    heartwood.url = "github:radicle-dev/heartwood";
    heartwood.inputs.crane.follows = "crane";

    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "heartwood/nixpkgs";
  };
  outputs = { self, nixpkgs, heartwood, ... }: {
    nixosModules = {
      default = import ./radicle.nix { inherit heartwood; };
      radicle-node = self.outputs.nixosModules.default;
    };
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.outputs.nixosModules.default
        ({ ... }: {
          services.radicle-node = {
            enable = true;
            enableWeb = false;
            alias = "example.org";
            port = 8776;
          };
          fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
          boot.loader.grub.device = "/dev/sda";
          system.stateVersion = "23.11";
        })
      ];
    };
  };
}
