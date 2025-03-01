{ inputs, ... }:
# A bunch of helper utilities for the project
let
  bpInputs = inputs;
  nixpkgs = bpInputs.nixpkgs;
  lib = nixpkgs.lib;

  # A generator for the top-level attributes of the flake.
  #
  # Designed to work with https://github.com/nix-systems
  mkEachSystem =
    {
      inputs,
      flake,
      systems,
      nixpkgs,
    }:
    let

      # Memoize the args per system
      systemArgs = lib.genAttrs systems (
        system:
        let
          # Resolve the packages for each input.
          perSystem = lib.mapAttrs (
            _: flake: flake.legacyPackages.${system} or { } // flake.packages.${system} or { }
          ) inputs;

          # Handle nixpkgs specially.
          pkgs =
            if (nixpkgs.config or { }) == { } && (nixpkgs.overlays or [ ]) == [ ] then
              perSystem.nixpkgs
            else
              import inputs.nixpkgs {
                inherit system;
                config = nixpkgs.config or { };
                overlays = nixpkgs.overlays or [ ];
              };
        in
        lib.makeScope lib.callPackageWith (_: {
          inherit
            inputs
            perSystem
            flake
            pkgs
            system
            ;
        })
      );

      eachSystem = f: lib.genAttrs systems (system: f systemArgs.${system});
    in
    {
      inherit systemArgs eachSystem;
    };

  optionalPathAttrs = path: f: lib.optionalAttrs (builtins.pathExists path) (f path);

  # Imports the path and pass the `args` to it if it exists, otherwise, return an empty attrset.
  tryImport = path: args: optionalPathAttrs path (path: import path args);

  # Maps all the nix files and folders in a directory to name -> path.
  importDir =
    path: fn:
    let
      entries = builtins.readDir path;

      # Get paths to directories
      onlyDirs = lib.filterAttrs (_name: type: type == "directory") entries;
      dirPaths = lib.mapAttrs (name: type: {
        path = path + "/${name}";
        inherit type;
      }) onlyDirs;

      # Get paths to nix files, where the name is the basename of the file without the .nix extension
      nixPaths = builtins.removeAttrs (lib.mapAttrs' (
        name: type:
        let
          nixName = builtins.match "(.*)\\.nix" name;
        in
        {
          name = if type == "directory" || nixName == null then "__junk" else (builtins.head nixName);
          value = {
            path = path + "/${name}";
            type = type;
          };
        }
      ) entries) [ "__junk" ];

      # Have the nix files take precedence over the directories
      combined = dirPaths // nixPaths;
    in
    lib.optionalAttrs (builtins.pathExists path) (fn combined);

  entriesPath = lib.mapAttrs (_name: { path, type }: path);

  # Prefixes all the keys of an attrset with the given prefix
  withPrefix =
    prefix:
    lib.mapAttrs' (
      name: value: {
        name = "${prefix}${name}";
        value = value;
      }
    );

  filterPlatforms =
    system: attrs:
    lib.filterAttrs (
      _: x:
      if (x.meta.platforms or [ ]) == [ ] then
        true # keep every package that has no meta.platforms
      else
        lib.elem system x.meta.platforms
    ) attrs;

  mkBlueprint' =
    {
      inputs,
      nixpkgs,
      flake,
      src,
      systems,
    }:
    let
      specialArgs = {
        inherit inputs flake;
        self = throw "self was renamed to flake";
      };

      inherit
        (mkEachSystem {
          inherit
            inputs
            flake
            nixpkgs
            systems
            ;
        })
        eachSystem
        systemArgs
        ;

      # Adds the perSystem argument to the NixOS and Darwin modules
      perSystemModule =
        { pkgs, ... }:
        {
          _module.args.perSystem = systemArgs.${pkgs.system}.perSystem;
        };

      home-manager =
        inputs.home-manager
          or (throw ''home configurations require Home Manager. To fix this, add `inputs.home-manager.url = "github:nix-community/home-manager";` to your flake'');

      # Sets up declared users without any user intervention, and sets the
      # options that most people would set anyway. The module is only returned
      # if home-manager is an input and the host has at least one user with a
      # home manager configuration. With this module, most users will not need
      # to manually configure Home Manager at all.
      mkHomeUsersModule =
        hostname: homeManagerModule:
        let
          module =
            { perSystem, ... }:
            {
              imports = [ homeManagerModule ];
              home-manager.sharedModules = [ perSystemModule ];
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users = homesNested.${hostname};
              home-manager.useGlobalPkgs = lib.mkDefault true;
              home-manager.useUserPackages = lib.mkDefault true;
            };
        in
        lib.optional (builtins.hasAttr hostname homesNested) module;

      homesGeneric =
        let
          getEntryPath =
            _username: userEntry:
            if builtins.pathExists (userEntry.path + "/home-configuration.nix") then
              userEntry.path + "/home-configuration.nix"
            else
              # If we decide to add users/<username>.nix, it's as simple as
              # testing `if userEntry.type == "regular"`
              null;

          mkUsers =
            userEntries:
            let
              users = lib.mapAttrs getEntryPath userEntries;
            in
            lib.filterAttrs (_name: value: value != null) users;
        in
        importDir (src + "/users") mkUsers;

      # Attribute set mapping hostname (defined in hosts/) to a set of home
      # configurations (modules) for that host. If a host has no home
      # configuration, it will be omitted from the set. Likewise, if the user
      # directory does not contain a home-configuration.nix file, it will
      # be silently omitted - not defining a configuration is not an error.
      homesNested =
        let
          getEntryPath =
            _username: userEntry:
            if userEntry.type == "regular" then
              userEntry.path
            else if builtins.pathExists (userEntry.path + "/home-configuration.nix") then
              userEntry.path + "/home-configuration.nix"
            else
              null;

          # Returns an attrset mapping username to home configuration path. It may be empty
          # if no users have a home configuration.
          mkHostUsers =
            userEntries:
            let
              hostUsers = lib.mapAttrs getEntryPath userEntries;
            in
            lib.filterAttrs (_name: value: value != null) hostUsers;

          mkHosts =
            hostEntries:
            let
              hostDirs = lib.filterAttrs (_: entry: entry.type == "directory") hostEntries;
              hostToUsers = _hostname: entry: importDir (entry.path + "/users") mkHostUsers;
              hosts = lib.mapAttrs hostToUsers hostDirs;
            in
            lib.filterAttrs (_hostname: users: users != { }) hosts;
        in
        importDir (src + "/hosts") mkHosts;

      # Attrset of ${system}.homeConfigurations."${username}@${hostname}"
      standaloneHomeConfigurations =
        let
          mkHomeConfiguration =
            {
              username,
              modulePath,
              pkgs,
            }:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = specialArgs;
              modules = [
                perSystemModule
                modulePath
                (
                  { config, ... }:
                  {
                    home.username = lib.mkDefault username;
                    # Home Manager would use builtins.getEnv prior to 20.09, but
                    # this feature was removed to make it pure. However, since
                    # we know the operating system and username ahead of time,
                    # it's safe enough to automatically set a default for the home
                    # directory and let users customize it if they want. This is
                    # done automatically in the NixOS or nix-darwin modules too.
                    home.homeDirectory =
                      let
                        username = config.home.username;
                        homeDir = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
                      in
                      lib.mkDefault homeDir;
                  }
                )
              ];
            };

          homesFlat = lib.concatMapAttrs (
            hostname: hostUserModules:
            lib.mapAttrs' (username: modulePath: {
              name = "${username}@${hostname}";
              value = {
                inherit hostname username modulePath;
              };
            }) hostUserModules
          ) homesNested;
        in
        eachSystem (
          { pkgs, ... }:
          {
            homeConfigurations =
              lib.mapAttrs (
                _name: homeData:
                mkHomeConfiguration {
                  inherit (homeData) modulePath username;
                  inherit pkgs;
                }
              ) homesFlat
              // lib.mapAttrs (
                username: modulePath: mkHomeConfiguration { inherit pkgs username modulePath; }
              ) homesGeneric;
          }
        );

      hosts = importDir (src + "/hosts") (
        entries:
        let
          loadDefaultFn = { class, value }@inputs: inputs;

          loadDefault = path: loadDefaultFn (import path { inherit flake inputs; });

          loadNixOS = hostname: path: {
            class = "nixos";
            value = inputs.nixpkgs.lib.nixosSystem {
              modules = [
                perSystemModule
                path
              ] ++ mkHomeUsersModule hostname home-manager.nixosModules.default;
              inherit specialArgs;
            };
          };

          loadNixDarwin =
            hostname: path:
            let
              nix-darwin =
                inputs.nix-darwin
                  or (throw ''${path} depends on nix-darwin. To fix this, add `inputs.nix-darwin.url = "github:Lnl7/nix-darwin";` to your flake'');
            in
            {
              class = "nix-darwin";
              value = nix-darwin.lib.darwinSystem {
                modules = [
                  perSystemModule
                  path
                ] ++ mkHomeUsersModule hostname home-manager.darwinModules.default;
                inherit specialArgs;
              };
            };

          loadHost =
            name:
            { path, type }:
            if builtins.pathExists (path + "/default.nix") then
              loadDefault (path + "/default.nix")
            else if builtins.pathExists (path + "/configuration.nix") then
              loadNixOS name (path + "/configuration.nix")
            else if builtins.pathExists (path + "/darwin-configuration.nix") then
              loadNixDarwin name (path + "/darwin-configuration.nix")
            else if builtins.hasAttr name homesNested then
              # If there are any home configurations defined for this host, they
              # must be standalone configurations since there is no OS config.
              # No config should be returned, but no error should be thrown either.
              null
            else
              throw "host '${name}' does not have a configuration";

          hostsOrNull = lib.mapAttrs loadHost entries;
        in
        lib.filterAttrs (_n: v: v != null) hostsOrNull
      );

      hostsByCategory = lib.mapAttrs (_: hosts: lib.listToAttrs hosts) (
        lib.groupBy (
          x:
          if x.value.class == "nixos" then
            "nixosConfigurations"
          else if x.value.class == "nix-darwin" then
            "darwinConfigurations"
          else
            throw "host '${x.name}' of class '${x.value.class or "unknown"}' not supported"
        ) (lib.attrsToList hosts)
      );

      publisherArgs = {
        inherit flake inputs;
      };

      expectsPublisherArgs =
        module:
        builtins.isFunction module
        && builtins.all (arg: builtins.elem arg (builtins.attrNames publisherArgs)) (
          builtins.attrNames (builtins.functionArgs module)
        );

      # Checks if the given module is wrapped in a function accepting one or more of publisherArgs.
      # If so, call that function. This allows modules to refer to the flake where it is
      # defined, while the module arguments "flake", "inputs" and "perSystem" refer to the flake
      # where the module is consumed.
      injectPublisherArgs =
        modulePath:
        let
          module = import modulePath;
        in
        if expectsPublisherArgs module then
          lib.setDefaultModuleLocation modulePath (module publisherArgs)
        else
          modulePath;

      modules =
        let
          path = src + "/modules";
          moduleDirs = builtins.attrNames (
            lib.filterAttrs (_name: value: value == "directory") (builtins.readDir path)
          );
        in
        lib.optionalAttrs (builtins.pathExists path) (
          lib.genAttrs moduleDirs (
            name:
            lib.mapAttrs (_name: moduleDir: injectPublisherArgs moduleDir) (
              importDir (path + "/${name}") entriesPath
            )
          )
        );
    in
    # FIXME: maybe there are two layers to this. The blueprint, and then the mapping to flake outputs.
    {
      formatter = eachSystem (
        { pkgs, perSystem, ... }:
        perSystem.self.formatter or (pkgs.writeShellApplication {
          name = "nixfmt-rfc-style";

          runtimeInputs = [
            pkgs.findutils
            pkgs.gnugrep
            pkgs.nixfmt-rfc-style
          ];

          text = ''
            set -euo pipefail

            # If no arguments are passed, default to formatting the whole project
            # If git it not available, fallback on current directory.
            if [[ $# = 0 ]]; then
              prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
              set -- "$prj_root"
            fi

            # Not a git repo, or git is not installed. Fallback
            if ! git rev-parse --is-inside-work-tree; then
              exec nixfmt "$@"
            fi

            # Use git to traverse since nixfmt doesn't have good traversal
            git ls-files "$@" | grep '\.nix$' | xargs --no-run-if-empty nixfmt
          '';
        })
      );

      lib = tryImport (src + "/lib") specialArgs;

      # expose the functor to the top-level
      # FIXME: only if it exists
      __functor = x: inputs.self.lib.__functor x;

      devShells =
        (optionalPathAttrs (src + "/devshells") (
          path:
          importDir path (
            entries:
            eachSystem (
              { newScope, ... }:
              lib.mapAttrs (pname: { path, type }: newScope { inherit pname; } path { }) entries
            )
          )
        ))
        // (optionalPathAttrs (src + "/devshell.nix") (
          path:
          eachSystem (
            { newScope, ... }:
            {
              default = newScope { pname = "default"; } path { };
            }
          )
        ));

      packages =
        lib.traceIf (builtins.pathExists (src + "/pkgs")) "blueprint: the /pkgs folder is now /packages"
          (
            let
              entries =
                (optionalPathAttrs (src + "/packages") (path: importDir path lib.id))
                // (optionalPathAttrs (src + "/package.nix") (path: {
                  default = {
                    inherit path;
                  };
                }))
                // (optionalPathAttrs (src + "/formatter.nix") (path: {
                  formatter = {
                    inherit path;
                  };
                }));
            in
            eachSystem (
              { newScope, ... }: lib.mapAttrs (pname: { path, ... }: newScope { inherit pname; } path { }) entries
            )
          );

      # Defining homeConfigurations under legacyPackages allows the home-manager CLI
      # to automatically detect the right output for the current system without
      # either manually defining the pkgs set (requires explicit system) or breaking
      # nix3 CLI output (`packages` output expects flat attrset)
      # FIXME: Find another way to make this work without introducing legacyPackages.
      #        May involve changing upstream home-manager.
      legacyPackages = standaloneHomeConfigurations;

      darwinConfigurations = lib.mapAttrs (_: x: x.value) (hostsByCategory.darwinConfigurations or { });
      nixosConfigurations = lib.mapAttrs (_: x: x.value) (hostsByCategory.nixosConfigurations or { });

      inherit modules;

      darwinModules = modules.darwin or { };
      homeModules = modules.home or { };
      # TODO: how to extract NixOS tests?
      nixosModules = modules.nixos or { };

      templates = importDir (src + "/templates") (
        entries:
        lib.mapAttrs (
          name:
          { path, type }:
          {
            path = path;
            description =
              if builtins.pathExists (path + "/flake.nix") then
                (import (path + "/flake.nix")).description or name
              else
                name;
          }
        ) entries
      );

      checks = eachSystem (
        { system, pkgs, ... }:
        lib.mergeAttrsList (
          [
            # add all the supported packages, and their passthru.tests to checks
            (withPrefix "pkgs-" (
              lib.concatMapAttrs (
                pname: package:
                {
                  ${pname} = package;
                }
                # also add the passthru.tests to the checks
                // (lib.mapAttrs' (tname: test: {
                  name = "${pname}-${tname}";
                  value = test;
                }) (filterPlatforms system (package.passthru.tests or { })))
              ) (filterPlatforms system (inputs.self.packages.${system} or { }))
            ))
            # build all the devshells
            (withPrefix "devshell-" (inputs.self.devShells.${system} or { }))
            # add nixos system closures to checks
            (withPrefix "nixos-" (
              lib.mapAttrs (_: x: x.config.system.build.toplevel) (
                lib.filterAttrs (_: x: x.pkgs.system == system) (inputs.self.nixosConfigurations or { })
              )
            ))
            # add darwin system closures to checks
            (withPrefix "darwin-" (
              lib.mapAttrs (_: x: x.system) (
                lib.filterAttrs (_: x: x.pkgs.system == system) (inputs.self.darwinConfigurations or { })
              )
            ))
            # load checks from the /checks folder. Those take precedence over the others.
            (filterPlatforms system (
              optionalPathAttrs (src + "/checks") (
                path:
                let
                  importChecksFn = lib.mapAttrs (
                    pname:
                    { type, path }:
                    import path {
                      inherit
                        pname
                        flake
                        inputs
                        system
                        pkgs
                        ;
                    }
                  );
                in

                (importDir path importChecksFn)
              )
            ))
          ]
          ++ (lib.optional (inputs.self.lib.tests or { } != { }) {
            lib-tests = pkgs.runCommandLocal "lib-tests" { nativeBuildInputs = [ pkgs.nix-unit ]; } ''
              export HOME="$(realpath .)"
              export NIX_CONFIG='
              extra-experimental-features = nix-command flakes
              flake-registry = ""
              '

              nix-unit --flake ${flake}#lib.tests ${
                toString (
                  lib.mapAttrsToList (k: v: "--override-input ${k} ${v}") (builtins.removeAttrs inputs [ "self" ])
                )
              }

              touch $out
            '';
          })
        )
      );
    };

  # Create a new flake blueprint
  mkBlueprint =
    {
      # Pass the flake inputs to blueprint
      inputs,
      # Load the blueprint from this path
      prefix ? null,
      # Used to configure nixpkgs
      nixpkgs ? {
        config = { };
      },
      # The systems to generate the flake for
      systems ? inputs.systems or bpInputs.systems,
    }:
    mkBlueprint' {
      inputs = bpInputs // inputs;
      flake = inputs.self;

      inherit nixpkgs;

      src =
        if prefix == null then
          inputs.self
        else if builtins.isPath prefix then
          prefix
        else if builtins.isString prefix then
          "${inputs.self}/${prefix}"
        else
          throw "${builtins.typeOf prefix} is not supported for the prefix";

      # Make compatible with github:nix-systems/default
      systems = if lib.isList systems then systems else import systems;
    };

  tests = {
    testPass = {
      expr = 1;
      expected = 1;
    };
  };
in
{
  inherit
    filterPlatforms
    importDir
    mkBlueprint
    tests
    tryImport
    withPrefix
    ;

  # Make this callable
  __functor = _: mkBlueprint;
}
