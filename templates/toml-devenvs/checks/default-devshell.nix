{ pkgs, inputs, ... }:
let
  # defined in devshell.toml at root of this flake.
  shell = inputs.self.devShells.${pkgs.system}.default;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "default-devshell";
  phases = [ "check" ];
  check = ''
    source ${shell}/entrypoint
    menu # log the shell menu
    hello | tee $out
  '';
}
