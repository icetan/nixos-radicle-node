{ heartwood }:
{ pkgs, config, lib, ... }:
let
  inherit (builtins)
    toJSON;

  inherit (lib)
    mkIf fold recursiveUpdate importJSON;

  inherit (pkgs.stdenv)
    system;

  inherit (pkgs)
    git sudo;

  inherit (heartwood.packages.${system})
    radicle-cli radicle-node;

  cfg = config.services.radicle-node;
in
{
  config = mkIf cfg.enable {
    users.extraUsers."${cfg.user}" = {
      name = cfg.user;
      group = cfg.user;
      home = cfg.home;
      createHome = true;
      isSystemUser = true;
    };
    users.extraGroups."${cfg.user}" = {
      name = "${cfg.user}";
    };

    systemd.services.radicle-node = {
      enable = true;

      after = [ "syslog.target" "network.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        User = cfg.user;
        WorkingDirectory = cfg.home;
        KillMode = "process";
        Restart = "always";
        RestartSec = "3";
        Environment = [
          "RAD_HOME=${cfg.home}/.radicle"
          "RUST_BACKTRACE=1"
          "RUST_LOG=info"
        ];
      };

      script = ''
        PATH="${git}/bin:$PATH"
        ${radicle-node}/bin/radicle-node \
          --listen ${cfg.host}:${toString cfg.port} \
          --force
      '';
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    system.activationScripts.radicle-node-setup =
      let
        defaultConfig.node = {
          policy = "allow";
          scope = "all";
        };

        fileConfig =
          if (builtins.isNull cfg.configFile)
          then { }
          else importJSON cfg.configFile;

        nixConfig.node = {
          inherit (cfg) alias externalAddresses;
        };

        finalConfig = fold recursiveUpdate { } [
          defaultConfig
          fileConfig
          nixConfig
          cfg.extraConfig
        ];

        nodeConfigFile = builtins.toFile "radicle-node-config.json"
          (toJSON finalConfig);

        privateKeyPath = toString cfg.privateKeyPath;
        publicKeyPath = toString cfg.publicKeyPath;
      in
      ''
        export RAD_HOME="${cfg.home}/.radicle"

        if [ -n "${privateKeyPath}" ] && [ -n "${publicKeyPath}" ]
        then
          mkdir -p "$RAD_HOME/keys"
          ln -sf "${privateKeyPath}" "$RAD_HOME/keys/radicle"
          ln -sf "${publicKeyPath}" "$RAD_HOME/keys/radicle.pub"
        fi

        if [ ! -e "$RAD_HOME/keys" ] || [ -z "$(ls -1 "$RAD_HOME/keys")" ]
        then
          echo \
          | ${sudo}/bin/sudo -u "${cfg.user}" \
            PATH="${git}/bin:$PATH" \
            ${radicle-cli}/bin/rad auth --stdin --alias "${cfg.alias}"
        fi

        ln -sf ${nodeConfigFile} "$RAD_HOME/config.json"

        ${radicle-cli}/bin/rad self
      '';
  };
}
