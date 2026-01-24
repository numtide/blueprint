{ inputs, pkgs, ... }:
let
  treefmtEval = inputs.treefmt.lib.evalModule pkgs ../treefmt.nix;
in
inputs.git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
  src = inputs.self;
  hooks = {
    nil.enable = true;
    statix.enable = true;
    treefmt = {
      enable = true;
      package = treefmtEval.config.build.wrapper;
    };
  };
}
