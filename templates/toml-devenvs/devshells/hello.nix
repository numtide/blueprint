# This is a nix syntax devshell (a derivation result of calling mkShell)
#
# On Nix-syntax shells, you are expected to call mkShell yourself, and
# the flake will expect the result of this function to be a derivation.
#
# There are many different flavours of mkShell in nix.
#
# * [nixpkgs]
#     These are the *classic* nix shells, created using `pkgs.mkShell`
#
# * [numtide/devshell](https://numtide.github.io/devshell/intro.html)
#     These kind of shells support a lot more of features and can be
#     created using TOML or Nix syntax. With support for importing modules.
#
#     When creating from a TOML, use: `perSystem.devshell.fromTOML ./some.toml`
#     When creating from a Nix expr, use: `perSystem.devshell.mkShell`
#
# While TOML syntax is simpler and mostly oriented to new users, the Nix syntax
# allows you to customize any package to your hearts content with the power of nix.
{ perSystem, pkgs, ... }:
perSystem.devshell.mkShell {
  imports = [
    # We can import a TOML module
    (perSystem.devshell.importTOML ./lolcat.toml)

    # And we cal also import Nix modules
    ./modules/bye.nix

    # However since bye.nix expects perSystem, we provide it here.
    { _module.args = { inherit perSystem; }; }
  ];
  commands = [ { package = pkgs.hello; } ];
}
