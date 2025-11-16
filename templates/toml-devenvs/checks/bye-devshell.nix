{ pkgs, inputs, ... }:
let
  # defined in devshells/bye.nix
  shell = inputs.self.devShells.${pkgs.stdenv.hostPlatform.system}.bye;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "hello-devshell";
  phases = [ "check" ];
  check = ''
    source ${shell}/entrypoint
    menu # log the shell menu
    check | tee $out
  '';
}
