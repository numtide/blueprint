{ pkgs, inputs, ... }:
let
  # defined in devshells/hello.nix
  shell = inputs.self.devShells.${pkgs.system}.hello;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "hello-devshell";
  phases = [ "check" ];
  check = ''
    source ${shell}/entrypoint
    menu # log the shell menu
    hello | lolcat > $out
  '';
}
