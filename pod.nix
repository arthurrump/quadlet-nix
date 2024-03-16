{ quadletUtils, pkgs }:
{ config, name, lib, ... }:

with lib;

let
  podOpts = {
    networks = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--network";
      property = "Network";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--cpus=2" ];
      description = "extra arguments to podman";
      property = "PodmanArgs";
    };

    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "--name";
      property = "PodName";
    };

    publishPorts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--publish";
      property = "PublishPort";
    };

    volumes = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      description = "--volume";
      property = "Volume";
    };
  };
in {
  options = {
    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the pod is automatically started on boot.";
    };
    podConfig = podOpts;
    unitConfig = mkOption {
      type = types.attrs;
      default = {};
    };
    serviceConfig = mkOption {
      type = types.attrs;
      default = {};
    };

    _configName = mkOption { internal = true; };
    _unitName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
  };

  config = let
    configRelPath = "containers/systemd/${name}.pod";
    podName = if config.podConfig.name != null
        then config.podConfig.name
        else "systemd-${name}";
    podConfig = config.podConfig;
    unitConfig = {
      Unit = {
        Description = "Podman pod ${name}";
      } // config.unitConfig;
      Install = {
        WantedBy = if config.autoStart then [ "default.target" ] else [];
      };
      Pod = quadletUtils.configToProperties podConfig podOpts;
      Service = {
        ExecStop = "${pkgs.podman}/bin/podman pod stop ${podName}";
      } // config.serviceConfig;
    };
  in {
    _configName = "${name}.pod";
    _unitName = "${name}-pod.service";
    _configText = quadletUtils.unitConfigToText unitConfig;
  };
}
