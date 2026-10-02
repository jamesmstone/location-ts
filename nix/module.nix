self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.location;
  name = "location";
in
{
  options.services.location = {
    enable = lib.mkEnableOption "the location log ingest endpoint";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "location.packages.\${system}.default";
      description = "The location server package to run.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3003;
      description = "Port the ingest endpoint listens on ($PORT).";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address to bind ($LOCATION_HOST).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = name;
      description = "User the service runs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = name;
      description = "Primary group of the service user.";
    };

    createUser = lib.mkOption {
      type = lib.types.bool;
      default = cfg.user == name;
      defaultText = lib.literalExpression ''cfg.user == "location"'';
      description = "Whether to declare the user and group.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/${name}";
      description = "Working directory holding the log.";
    };

    dataFile = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.stateDir}/location.jsonl";
      defaultText = lib.literalExpression ''"''${cfg.stateDir}/location.jsonl"'';
      description = "JSONL file each posted payload is appended to ($LOCATION_FILE).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the listening port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf cfg.createUser {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.stateDir;
        description = "Location log ingest endpoint";
      };
    };

    users.groups = lib.mkIf cfg.createUser { ${cfg.group} = { }; };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.location = {
      description = "Location log ingest endpoint";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        PORT = toString cfg.port;
        LOCATION_HOST = cfg.host;
        LOCATION_FILE = cfg.dataFile;
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe cfg.package;
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 5;
        WorkingDirectory = cfg.stateDir;
        StateDirectory = lib.mkIf (cfg.stateDir == "/var/lib/${name}") name;
      };
    };
  };
}
