{ pkgs, ... }: pkgs.writeShellScriptBin "bye" ''echo Bye "$@"''
