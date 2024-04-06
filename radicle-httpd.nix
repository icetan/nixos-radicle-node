{ heartwood }:
{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkIf;

  inherit (pkgs.stdenv)
    system;

  inherit (pkgs)
    git;

  inherit (heartwood.packages.${system})
    radicle-httpd;

  cfg = config.services.radicle-node;
in
{
  config = mkIf (cfg.enable && cfg.enableWeb) {
    systemd.services.radicle-httpd = {
      enable = true;

      after = [ "syslog.target" "network.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        User = cfg.user;
        WorkingDirectory = cfg.home;
        KillMode = "process";
        Restart = "always";
        RestartSec = "1";
        Environment = [
          "RAD_HOME=${cfg.home}/.radicle"
          "RUST_BACKTRACE=1"
          "RUST_LOG=info"
        ];
      };

      script = ''
        PATH="${git}/bin:$PATH"
        ${radicle-httpd}/bin/radicle-httpd \
          --listen 127.0.0.1:8778
      '';
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.alias} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8778";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
