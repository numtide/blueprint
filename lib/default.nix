{ nixpkgs, ... }@bpInputs:
# A bunch of helper utilities for the project
let
  lib = nixpkgs.lib;

  # A generator for the top-level attributes of the flake.
  #
  # Designed to work with nix-systems
  mkEachSystem =
    { systems, nixpkgs, ... }@inputs:
    let
      # make compatible with github:nix-systems/default
      sys = if lib.isList systems then systems else import systems;
      # memoize the args per system
      args = lib.genAttrs sys (
        system:
        let
          # resolve the packages for each input
          inputs' = lib.mapAttrs (
            _: flake: (flake.packages or flake.legacyPackages or { }).${system} or { }
          ) inputs;
        in
        inputs'
        // {
          # add system as a special, non-overridable value
          inherit system;

          # handle nixpkgs specially.
          pkgs = inputs'.nixpkgs;
        }
      );
    in
    f: lib.genAttrs sys (system: f args.${system});

  ifDir = path: lib.optionalAttrs (builtins.pathExists path);

  # Imports the path and pass the `args` to it if it exists, otherwise, return an empty attrset.
  tryImport = path: args: ifDir path (import path args);

  importDir =
    path: fn:
    let
      entries = builtins.readDir path;
      # TODO: is it possible to use symlinks as aliases? For example to set the default package.
      onlyDirs = lib.filterAttrs (name: type: type == "directory") entries;
      # add the full path as a value
      withPaths = lib.mapAttrs (name: _: path + "/${name}") onlyDirs;
    in
    lib.optionalAttrs (builtins.pathExists path) (fn withPaths);

  # Prefixes all the keys of an attrset with the given prefix
  withPrefix =
    prefix:
    lib.mapAttrs' (
      name: value: {
        name = "${prefix}${name}";
        value = value;
      }
    );

  # Create a new flake blueprint
  mkFlake =
    { inputs }:
    (
      { inputs }:
      let
        eachSystem = mkEachSystem inputs;
        src = inputs.self;
      in
      {
        # FIXME: make this configurable
        formatter = eachSystem ({ nixpkgs, ... }: nixpkgs.nixfmt-rfc-style);

        lib = tryImport (src + /lib) inputs;

        # expose the functor to the top-level
        # FIXME: only if it exists
        __functor = x: inputs.self.lib.__functor x;

        # FIXME: make this extensible
        devShells = eachSystem (
          { pkgs, ... }:
          {
            default = pkgs.mkShellNoCC {
              packages = [
                # Some default tooling everybody should have
                pkgs.nix-init
                pkgs.nix-update
              ];
            };
          }
        );

        packages = importDir (src + "/pkgs") (
          entries:
          eachSystem (args: lib.mapAttrs (pname: path: import path (args // { inherit pname; })) entries)
        );

        templates = importDir (src + "/templates") (
          entries:
          lib.mapAttrs (name: path: {
            path = path;
            # FIXME: how can we add something more meaningful?
            description = name;
          }) entries
        );

        checks = eachSystem (
          { system, ... }:
          lib.mergeAttrsList [
            # add all the supported packages to checks
            (withPrefix "pkgs-" (
              lib.filterAttrs (
                _: x: if x.meta ? platforms then lib.elem system x.meta.platforms else true # keep every package that has no meta.platforms
              ) inputs.self.packages.${system}
            ))
            # build all the devshells
            (withPrefix "devshell-" inputs.self.devShells.${system})
          ]
        );
      }
    )
      { inputs = bpInputs // inputs; };
in
{
  inherit mkFlake;

  # Make this callable
  __functor = _: mkFlake;
}
