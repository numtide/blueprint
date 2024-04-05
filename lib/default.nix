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
          perSystem = lib.mapAttrs (
            _: flake: (flake.packages or flake.legacyPackages or { }).${system} or { }
          ) inputs;
        in
        {
          # add system as a special, non-overridable value
          inherit inputs perSystem system;

          # add shortcut for self
          self = inputs.self;

          # handle nixpkgs specially.
          pkgs = perSystem.nixpkgs;
        }
      );
    in
    f: lib.genAttrs sys (system: f args.${system});

  ifDir = path: lib.optionalAttrs (builtins.pathExists path);

  # Imports the path and pass the `args` to it if it exists, otherwise, return an empty attrset.
  tryImport = path: args: ifDir path (import path args);

  # Maps all the nix files and folders in a directory to name -> path.
  importDir =
    path: fn:
    let
      entries = builtins.readDir path;

      # Get paths to directories
      onlyDirs = lib.filterAttrs (name: type: type == "directory") entries;
      dirPaths = lib.mapAttrs (name: _: path + "/${name}") onlyDirs;

      # Get paths to nix files, where the name is the basename of the file without the .nix extension
      nixPaths = builtins.removeAttrs (lib.mapAttrs' (
        name: type:
        let
          nixName = builtins.match "(.*)\\.nix" name;
        in
        {
          name = if type == "directory" || nixName == null then "__junk" else (builtins.head nixName);
          value = path + "/${name}";
        }
      ) entries) [ "__junk" ];

      # Have the nix files take precedence over the directories
      combined = dirPaths // nixPaths;
    in
    lib.optionalAttrs (builtins.pathExists path) (fn combined);

  # Prefixes all the keys of an attrset with the given prefix
  withPrefix =
    prefix:
    lib.mapAttrs' (
      name: value: {
        name = "${prefix}${name}";
        value = value;
      }
    );

  isNixOS = attrs: (attrs.config.system or { }) ? nixos;

  # Create a new flake blueprint
  mkFlake =
    {
      # Pass the flake inputs to the blueprint
      inputs,
      # Load the blueprint from this path
      prefix ? "",
    }:
    (
      { inputs }:
      let
        eachSystem = mkEachSystem inputs;
        src = if prefix == "" then inputs.self else "${inputs.self}/${prefix}";

        hosts = importDir (src + "/hosts") (
          entries:
          let
            # Something to pass to all the systems
            specialArgs = {
              inherit inputs;
              # shortcut for self
              self = inputs.self;
            };

            loadNixOS =
              path:
              # FIXME: we assume it's using the nixpkgs input. How do you switch to another one?
              inputs.nixpkgs.lib.nixosSystem {
                modules = [ path ];
                inherit specialArgs;
              };

            loadHost =
              name: path:
              if builtins.pathExists (path + "/configuration.nix") then
                loadNixOS (path + "/configuration.nix")
              else
                throw "${name} does not have a configuration.nix";
          in
          lib.mapAttrs loadHost entries
        );

        hostsByCategory = lib.mapAttrs (_: hosts: lib.listToAttrs hosts) (
          lib.groupBy (
            x: if isNixOS x.value then "nixosConfigurations" else throw "${x.name} type not supported"
          ) (lib.attrsToList hosts)
        );

        modules = {
          common = importDir (src + "/modules/common") lib.id;
          darwin = importDir (src + "/modules/darwin") lib.id;
          home = importDir (src + "/modules/home") lib.id;
          nixos = importDir (src + "/modules/nixos") lib.id;
        };
      in
      # FIXME: maybe there are two layers to this. The blueprint, and then the mapping to flake outputs.
      {
        # FIXME: make this configurable
        formatter = eachSystem ({ pkgs, ... }: pkgs.nixfmt-rfc-style);

        lib = tryImport (src + "/lib") inputs;

        # expose the functor to the top-level
        # FIXME: only if it exists
        __functor = x: inputs.self.lib.__functor x;

        devShells = eachSystem (
          args:
          if builtins.pathExists (src + "/devshell.nix") then
            # FIXME: do we want to support multiple shells?
            { default = import (src + "/devshell.nix") args; }
          else
            # TODO: what would a default shell look like?
            { }
        );

        packages = importDir (src + "/pkgs") (
          entries:
          eachSystem (args: lib.mapAttrs (pname: path: import path (args // { inherit pname; })) entries)
        );

        nixosConfigurations = hostsByCategory.nixosConfigurations or { };

        inherit modules;
        darwinModules = modules.darwin;
        homeModules = modules.home;
        # TODO: how to extract NixOS tests?
        nixosModules = modules.nixos;

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
            # FIXME: also add all the meta.tests attributes
            (withPrefix "pkgs-" (
              lib.filterAttrs (
                _: x: if x.meta ? platforms then lib.elem system x.meta.platforms else true # keep every package that has no meta.platforms
              ) (inputs.self.packages.${system} or { })
            ))
            # build all the devshells
            (withPrefix "devshell-" (inputs.self.devShells.${system} or { }))
            # add nixos system closures to checks
            (withPrefix "nixos-" (
              lib.mapAttrs (_: x: x.config.system.build.toplevel) (
                lib.filterAttrs (_: x: x.pkgs.system == system) (inputs.self.nixosConfigurations or { })
              )
            ))
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
