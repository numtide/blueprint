{ pkgs, inputs, ... }:
let
  # defined in devshell.toml at root of this flake.
  defaultShell = inputs.self.devShells.${pkgs.system}.default;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "default-devshell";
  phases = [ "check" ];
  check = ''
    source ${defaultShell}/entrypoint
    menu # log the shell menu
    goodbye-cruel-world > $out
  '';
}
