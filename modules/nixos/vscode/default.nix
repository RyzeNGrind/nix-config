# VSCode support module
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.vscode;
in {
  options.services.vscode = {
    enable = mkEnableOption (mdDoc "VSCode IDE support");

    remote = {
      enable = mkEnableOption (mdDoc "VSCode remote development support");

      package = mkOption {
        type = types.package;
        default = pkgs.nodejs_20;
        defaultText = literalExpression "pkgs.nodejs_20";
        description = mdDoc "The Node.js package to use for VSCode remote server.";
      };

      user = mkOption {
        type = types.str;
        default = "ryzengrind";
        description = mdDoc "User account under which VSCode remote server runs.";
      };

      extraEnv = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = literalExpression ''
          {
            HTTP_PROXY = "http://proxy.local";
            HTTPS_PROXY = "https://proxy.local";
          }
        '';
        description = mdDoc "Extra environment variables for VSCode remote server.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Basic VSCode support
      environment.systemPackages = with pkgs; [
        wget
        curl
        jq
      ];
    }

    (mkIf cfg.remote.enable {
      # VSCode remote workaround service
      systemd.user.services.vscode-remote-workaround = {
        description = "VSCode Remote Server Node.js Workaround";
        wantedBy = ["default.target"];
        after = ["network.target"];

        environment =
          {
            VSCODE_WSL_DEBUG_INFO = "true";
            NIXOS_OZONE_WL = "1"; # For Wayland support
          }
          // cfg.remote.extraEnv;

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = cfg.remote.user;
          ExecStart = pkgs.writeShellScript "vscode-remote-workaround" ''
            echo "Configuring VSCode remote server with ${cfg.remote.package}"
            for server_dir in ~/.vscode-server/bin/*; do
              if [ -d "$server_dir" ]; then
                echo "Fixing vscode-server in $server_dir..."
                ln -sf ${cfg.remote.package}/bin/node $server_dir/node
              fi
            done
          '';
        };
      };

      # Path watcher to trigger workaround on new server installs
      systemd.user.paths.vscode-remote-workaround = {
        wantedBy = ["default.target"];
        pathConfig.PathChanged = "%h/.vscode-server/bin";
      };

      # Configure SSH to accept VSCode environment variables
      services.openssh.extraConfig = mkIf config.services.openssh.enable ''
        AcceptEnv VSCODE_WSL_EXT_LOCATION
        AcceptEnv VSCODE_SERVER_TAR
        AcceptEnv VSCODE_AGENT_FOLDER
        AcceptEnv VSCODE_INJECT_NODE_PATH
        AcceptEnv NODE_EXTRA_CA_CERTS
      '';

      # Add user to required groups
      users.users.${cfg.remote.user}.extraGroups = ["vscode-remote"];
      users.groups.vscode-remote = {};
    })
  ]);
}
