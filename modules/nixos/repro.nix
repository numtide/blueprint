{ pkgs, config, ... }:

{
  options.repro = {
    enable = pkgs.lib.mkOption {
      default = false;
    };
  };
  config = pkgs.lib.mkIf config.repro.enable {
  };
}
