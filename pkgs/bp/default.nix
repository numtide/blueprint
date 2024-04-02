{ pname, pkgs, ... }:
pkgs.writeShellApplication {
  name = pname;
  runtimeInputs = [ ];
  text = ''
    echo "Blueprint!"
  '';
}
