{ inputs, pkgs, ... }:
let
  treefmtEval = inputs.treefmt.lib.evalModule pkgs ./treefmt.nix;
in
treefmtEval.config.build.wrapper
