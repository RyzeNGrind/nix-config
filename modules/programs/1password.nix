{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.programs._1password;

  # Create a system group for 1Password token access
  opGroup = "onepassword-secrets";
in {
  options.programs._1password = {
    enable = mkEnableOption "1Password";

    enableSshAgent = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 1Password SSH agent integration";
    };

    enableGitCredentialHelper = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 1Password git credential helper";
    };

    tokenFile = mkOption {
      type = types.path;
      default = "/etc/1password/op-token";
      description = "Path to 1Password service account token file";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Users that should have access to 1Password token through group membership";
      example = ["alice" "bob"];
    };
  };

  config = mkIf cfg.enable {
    # Create the 1Password group
    users.groups.${opGroup} = {};

    # Add specified users to the 1Password group
    users.users = lib.mkMerge (map (user: {
        ${user}.extraGroups = [opGroup];
      })
      cfg.users);

    # Install 1Password
    environment.systemPackages = with pkgs; [
      _1password
      _1password-gui
      openssh
    ];

    # Configure polkit rules for 1Password
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "com.1password.1Password.unlock" &&
            subject.isInGroup("${opGroup}")) {
            return polkit.Result.YES;
        }
      });
    '';

    # SSH agent configuration
    programs.ssh = mkIf cfg.enableSshAgent {
      startAgent = false;
      extraConfig = ''
        # Use 1Password SSH agent
        Host *
          IdentityAgent ~/.1password/agent.sock
      '';
    };

    # Git credential helper configuration
    programs.git = mkIf cfg.enableGitCredentialHelper {
      enable = true;
      config = {
        credential.helper = "op";
      };
    };

    # System-wide environment variables
    environment.sessionVariables = {
      SSH_AUTH_SOCK = "~/.1password/agent.sock";
    };

    # Token file setup in activation script
    system.activationScripts.onepassword-setup = {
      deps = [];
      text = ''
        # Create token directory with correct permissions
        mkdir -p $(dirname ${cfg.tokenFile})
        chmod 750 $(dirname ${cfg.tokenFile})

        # Set up token file with correct group permissions if it exists
        if [ -f ${cfg.tokenFile} ]; then
          chown root:${opGroup} ${cfg.tokenFile}
          chmod 640 ${cfg.tokenFile}
        fi
      '';
    };

    # Enable required services
    systemd.user.services = {
      _1password = {
        enable = true;
        description = "1Password";
        wantedBy = ["default.target"];
        path = [pkgs._1password];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs._1password}/bin/1password --silent";
        };
      };

      _1password-ssh-agent = mkIf cfg.enableSshAgent {
        enable = true;
        description = "1Password SSH Agent";
        wantedBy = ["default.target"];
        path = [pkgs._1password];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs._1password}/bin/op-ssh-sign";
        };
      };
    };
  };
}
