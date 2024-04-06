{ heartwood }:
{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkIf mkOption mkEnableOption types;

  inherit (pkgs.stdenv)
    system;

  inherit (heartwood.packages.${system})
    radicle-cli radicle-node;

  cfg = config.services.radicle-node;
in
{
  options.services.radicle-node = {
    enable = mkEnableOption "radicle-node";

    alias = mkOption {
      type = types.str;
      description = ''
        Node alias.
      '';
    };

    externalAddresses = mkOption {
      type = types.listOf types.str;
      description = ''
        External addresses.
      '';
      default = [ "${cfg.alias}:${toString cfg.port}" ];
    };

    host = mkOption {
      type = types.str;
      description = ''
        Host to bind to.
      '';
      default = "0.0.0.0";
    };

    port = mkOption {
      type = types.port;
      default = 8776;
      description = ''
        Port to bind to.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Configuration JSON files.
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Config overriding content of `configFile`.
      '';
    };

    privateKeyPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to private key.
      '';
    };

    publicKeyPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to public key.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "radicle-node";
      description = ''
        System user name.
      '';
    };

    home = mkOption {
      type = types.path;
      default = "/var/lib/${cfg.user}";
      description = ''
        System user home path.
      '';
    };

    enableWeb = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Start web API.
      '';
    };
  };

  imports = [
    (import ./radicle-node.nix { inherit heartwood; })
    (import ./radicle-httpd.nix { inherit heartwood; })
  ];
}
