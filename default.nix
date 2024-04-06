let
  flake = (import
    (
      let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
      fetchTarball {
        url = lock.nodes.flake-compat.locked.url or "https://github.com/9999years/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
    ) { src = ./.; }
  ).defaultNix;
in
import ./radicle.nix {
  inherit (flake.inputs)
    heartwood;
}

