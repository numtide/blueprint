{ pkgs, ... }: pkgs.writeShellScriptBin "bye" ''echo Goodbye "$@"''
