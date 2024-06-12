{
  pkgs,
  system,
  inputs,
  ...
}:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = ".git/config";

  programs = {
    nixfmt-rfc-style.enable = true;
  };
}
