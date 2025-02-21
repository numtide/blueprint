# This devenv module shows how to access packages from the defining flake.
#
# NOTE: The difference between a module and a devenv is that
# a module is just an attribute set as any other nix-module,
# and not a derivation (you don't call mkShell directly).
{ perSystem, lib, ... }:
{

  # Access packages defined on this flake by using perSystem.self
  commands = [ { package = perSystem.self.bye; } ];

}
