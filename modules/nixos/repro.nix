{ pkgs, flake, config, ... }:

let
  cfg = config.repro;
in {
  options.repro = {
    enable = pkgs.lib.mkOption {
      default = false;
    };
  };

  config = pkgs.lib.mkIf cfg.enable {
    environment.variables.NIXPKGS_REV =  flake.inputs.nixpkgs.rev;
  };
}
