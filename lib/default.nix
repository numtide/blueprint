{ inputs, ... }:
# A bunch of helper utilities for the Blueprint project
let
  bpInputs = inputs;
  nixpkgs = bpInputs.nixpkgs;
  lib = nixpkgs.lib;
in
rec {
  /**
    Generate the top-level per-system attributes for a flake.

    Designed to work with https://github.com/nix-systems.

    This function memoises per-system arguments in `systemArgs` and exposes an
    `eachSystem` helper that maps a callback over all supported systems.

    # Type

    ```
    mkEachSystem :: {
      inputs :: AttrSet,
      flake :: AttrSet,
      systems :: [ String ],
      nixpkgs :: { config :: AttrSet; overlays :: [ Overlay ]; },
      unfilteredPackages :: AttrSet,
    } -> { systemArgs :: AttrSet; eachSystem :: (AttrSet -> AttrSet) -> AttrSet; }
    ```

    # Arguments

    inputs
    : The flake inputs.

    flake
    : The current flake (`inputs.self`).

    systems
    : List of supported systems.

    nixpkgs
    : nixpkgs configuration (`config` and/or `overlays`).

    unfilteredPackages
    : Per-system package set, used to break the `perSystem` ↔ `packages`
      infinite recursion.
  */
  mkEachSystem =
    {
      inputs,
      flake,
      systems,
      nixpkgs,
      # We need to treat the packages that are being defined in self differently,
      # since otherwise we trigger infinite recursion when perSystem is defined in
      # terms of the packages defined by self, and self uses perSystem to define
      # its packages.
      # We run into the infrec when trying to filter out packages based on their
      # meta attributes, since that actually requires evaluating the package's derivation
      # and can then in turn change the value of perSystem (by removing packages),
      # which then requires to evaluate the package again, and so on and so forth.
      # To break this cycle, we define perSystem in terms of the filesystem hierarchy,
      # and not based on self.packages, and we don't apply any filtering based on
      # meta attributes yet.
      # The actual self.packages, can then be the filtered set of packages.
      unfilteredPackages,
    }:
    let
      # Memoize the args per system
      systemArgs = lib.genAttrs systems (
        system:
        let
          perSystem = mkPerSystem {
            inherit inputs system;
            selfPackages = unfilteredPackages.${system};
          };

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

  /**
    Apply `f` to `path` if it exists, returning an empty attribute set otherwise.

    # Type

    ```
    optionalPathAttrs :: Path -> (Path -> AttrSet) -> AttrSet
    ```

    # Arguments

    path
    : The filesystem path to check.

    f
    : Function called with `path` when it exists.
  */
  optionalPathAttrs = path: f: lib.optionalAttrs (builtins.pathExists path) (f path);

  /**
    Import `path` with `args` if it exists, returning an empty attribute set otherwise.

    # Type

    ```
    tryImport :: Path -> AttrSet -> AttrSet
    ```

    # Arguments

    path
    : The Nix file to import.

    args
    : The attribute set passed to the imported expression.
  */
  tryImport = path: args: optionalPathAttrs path (path: import path args);

  /**
    Map every `.toml` file in `path` to a name -> { path, type } attribute set.

    Names are derived from the basename without the `.toml` extension.

    # Type

    ```
    importTomlFilesAt :: Path -> (AttrSet -> AttrSet) -> AttrSet
    ```

    # Arguments

    path
    : The directory to scan.

    fn
    : Callback that receives the resulting attribute set.
  */
  importTomlFilesAt =
    path: fn:
    let
      entries = builtins.readDir path;

      # Get paths to toml files, where the name is the basename of the file without the .toml extension
      nixPaths = builtins.removeAttrs (lib.mapAttrs' (
        name: type:
        let
          nixName = builtins.match "(.*)\\.toml" name;
        in
        {
          name = if type == "directory" || nixName == null then "__junk" else (builtins.head nixName);
          value = {
            path = path + "/${name}";
            type = type;
          };
        }
      ) entries) [ "__junk" ];
    in
    lib.optionalAttrs (builtins.pathExists path) (fn nixPaths);

  /**
    Map Nix files and directories in `path` to a name -> { path, type } attribute set.

    Directories are included as-is. Regular `.nix` files are keyed by their
    basename without the `.nix` extension and take precedence over a directory
    with the same name.

    # Type

    ```
    importDir :: Path -> (AttrSet -> AttrSet) -> AttrSet
    ```

    # Arguments

    path
    : The directory to scan.

    fn
    : Callback that receives the resulting attribute set.
  */
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

  /**
    Extract just the `path` value from an attribute set of `{ path, type }` entries.

    Useful as the callback for `importDir` when only the path is needed.

    # Type

    ```
    entriesPath :: AttrSet -> AttrSet
    ```
  */
  entriesPath = lib.mapAttrs (_name: { path, type }: path);

  /**
    Prefix every key of an attribute set with `prefix`.

    # Type

    ```
    withPrefix :: String -> AttrSet -> AttrSet
    ```

    # Arguments

    prefix
    : String prepended to each key.
  */
  withPrefix =
    prefix:
    lib.mapAttrs' (
      name: value: {
        name = "${prefix}${name}";
        value = value;
      }
    );

  /**
    Resolve `perSystem.<input>` for every flake input.

    For `inputs.self`, `selfPackages` is merged instead of
    `self.packages.${system}` so the caller can break the
    `packages → filterPlatforms → perSystem.self → packages` cycle
    (see the comment on `unfilteredPackages` in `mkEachSystem`) and,
    in the overlay case, point intra-set references at the set built
    against the caller's nixpkgs.

    # Type

    ```
    mkPerSystem :: {
      inputs :: AttrSet,
      system :: String,
      selfPackages :: AttrSet,
    } -> AttrSet
    ```

    # Arguments

    inputs
    : The flake inputs.

    system
    : The system to resolve for.

    selfPackages
    : The package set used for `inputs.self`.
  */
  mkPerSystem =
    {
      inputs,
      system,
      selfPackages,
    }:
    lib.mapAttrs (
      name: input:
      (input.legacyPackages.${system} or { })
      // (if name == "self" then selfPackages else input.packages.${system} or { })
    ) inputs;

  /**
    Filter an attribute set of derivations to those that support `system`.

    Derivations without `meta.platforms` are kept unconditionally.

    # Type

    ```
    filterPlatforms :: String -> AttrSet -> AttrSet
    ```

    # Arguments

    system
    : The platform to keep packages for.

    attrs
    : The attribute set of derivations to filter.
  */
  filterPlatforms =
    system: attrs:
    lib.filterAttrs (
      _: x:
      if (x.meta.platforms or [ ]) == [ ] then
        true # keep every package that has no meta.platforms
      else
        lib.elem system x.meta.platforms
    ) attrs;

  /**
    Internal implementation of `mkBlueprint`.

    Builds the complete set of flake outputs from the project folder structure
    under `src`. Use `mkBlueprint` instead unless you need to override internal
    wiring.

    # Type

    ```
    mkBlueprint' :: {
      inputs :: AttrSet,
      nixpkgs :: AttrSet,
      flake :: AttrSet,
      src :: Path,
      systems :: [ String ],
    } -> AttrSet
    ```

    # Arguments

    inputs
    : The flake inputs.

    nixpkgs
    : nixpkgs configuration (`config` and/or `overlays`).

    flake
    : The current flake (`inputs.self`).

    src
    : The project source path.

    systems
    : List of supported systems.
  */
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
            unfilteredPackages
            ;
        })
        eachSystem
        systemArgs
        ;

      # Adds the perSystem argument to the NixOS and Darwin modules
      perSystemArgsModule = system: {
        _module.args.perSystem = systemArgs.${system}.perSystem;
      };

      perSystemModule =
        { config, lib, ... }:
        {
          imports = [ (perSystemArgsModule config.nixpkgs.hostPlatform.system) ];
        };

      perSystemHMModule =
        { osConfig, ... }:
        {
          imports = [ (perSystemArgsModule osConfig.nixpkgs.hostPlatform.system) ];
        };

      perSystemSMModule =
        { config, lib, ... }:
        {
          imports = [ (perSystemArgsModule config.nixpkgs.hostPlatform) ];
        };

      # Share the per-system pkgs blueprint already instantiated (with the
      # configured nixpkgs.config/overlays applied) instead of having the
      # NixOS/nix-darwin module system import nixpkgs a second time with
      # the same settings.
      #
      # Only injected when blueprint actually has config/overlays to
      # propagate; otherwise hosts keep full control of their nixpkgs.*
      # options. mkDefault so a host can still set its own nixpkgs.pkgs.
      nixpkgsConfigModule =
        if (nixpkgs.config or { }) == { } && (nixpkgs.overlays or [ ]) == [ ] then
          { }
        else
          (
            { config, lib, ... }:
            {
              nixpkgs.pkgs = lib.mkDefault systemArgs.${config.nixpkgs.hostPlatform.system}.pkgs;
            }
          );

      home-manager =
        inputs.home-manager
          or (throw ''home configurations require Home Manager. To fix this, add `inputs.home-manager.url = "github:nix-community/home-manager";` to your flake'');

      devshellFromTOML =
        perSystem: path:
        let
          devshell =
            perSystem.devshell
              or (throw ''Loading TOML devshells requires `inputs.devshell.url = "github:numtide/devshell";` in your flake'');
        in
        devshell.mkShell {
          _module.args = {
            inherit perSystem;
          }; # so that devshell modules can access self exported packages.
          imports = [ (devshell.importTOML path) ];
        };

      # Sets up declared users without any user intervention, and sets the
      # options that most people would set anyway. The module is only returned
      # if home-manager is an input and the host has at least one user with a
      # home manager configuration. With this module, most users will not need
      # to manually configure Home Manager at all.
      mkHomeUsersModule =
        hostname: homeManagerModule:
        let
          module =
            { perSystem, config, ... }:
            {
              imports = [ homeManagerModule ];
              home-manager.sharedModules = [ perSystemHMModule ];
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users = homesNested.${hostname};
              home-manager.useGlobalPkgs = lib.mkDefault true;
              home-manager.useUserPackages = lib.mkDefault true;
            };
        in
        lib.optional (builtins.hasAttr hostname homesNested) module;

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
              system,
            }:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = specialArgs;
              modules = [
                (perSystemArgsModule system)
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
          { pkgs, system, ... }:
          {
            homeConfigurations = lib.mapAttrs (
              _name: homeData:
              mkHomeConfiguration {
                inherit (homeData) modulePath username;
                inherit pkgs system;
              }
            ) homesFlat;
          }
        );

      hosts = importDir (src + "/hosts") (
        entries:
        let
          loadDefaultFn = { class, value }@inputs: inputs;

          loadDefault = hostName: path: loadDefaultFn (import path { inherit flake inputs hostName; });

          loadNixOS = hostName: path: {
            class = "nixos";
            value = inputs.nixpkgs.lib.nixosSystem {
              modules = [
                nixpkgsConfigModule
                perSystemModule
                path
              ]
              ++ mkHomeUsersModule hostName home-manager.nixosModules.default;
              specialArgs = specialArgs // {
                inherit hostName;
              };
            };
          };

          loadNixOSRPi =
            hostName: path:
            let
              nixos-raspberrypi =
                inputs.nixos-raspberrypi
                  or (throw ''${path} depends on nixos-raspberrypi. To fix this, add `inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";` to your flake'');
            in
            {
              class = "nixos";
              value = nixos-raspberrypi.lib.nixosSystem {
                modules = [
                  nixpkgsConfigModule
                  perSystemModule
                  path
                ]
                ++ mkHomeUsersModule hostName home-manager.nixosModules.default;
                specialArgs = specialArgs // {
                  inherit hostName;
                  nixos-raspberrypi = inputs.nixos-raspberrypi;
                };
              };
            };

          loadNixDarwin =
            hostName: path:
            let
              nix-darwin =
                inputs.nix-darwin
                  or (throw ''${path} depends on nix-darwin. To fix this, add `inputs.nix-darwin.url = "github:Lnl7/nix-darwin";` to your flake'');
            in
            {
              class = "nix-darwin";
              value = nix-darwin.lib.darwinSystem {
                modules = [
                  nixpkgsConfigModule
                  perSystemModule
                  path
                ]
                ++ mkHomeUsersModule hostName home-manager.darwinModules.default;
                specialArgs = specialArgs // {
                  inherit hostName;
                };
              };
            };

          loadSystemManager =
            hostName: path:
            let
              system-manager =
                inputs.system-manager
                  or (throw ''${path} depends on system-manager. To fix this, add `inputs.system-manager.url = "github:numtide/system-manager"; to your flake'');
            in
            {
              class = "system-manager";
              value = system-manager.lib.makeSystemConfig {
                modules = [
                  perSystemSMModule
                  path
                ];
                extraSpecialArgs = specialArgs // {
                  inherit hostName;
                };
              };
            };

          loadHost =
            name:
            { path, type }:
            if builtins.pathExists (path + "/default.nix") then
              loadDefault name (path + "/default.nix")
            else if builtins.pathExists (path + "/configuration.nix") then
              loadNixOS name (path + "/configuration.nix")
            else if builtins.pathExists (path + "/rpi-configuration.nix") then
              loadNixOSRPi name (path + "/rpi-configuration.nix")
            else if builtins.pathExists (path + "/darwin-configuration.nix") then
              loadNixDarwin name (path + "/darwin-configuration.nix")
            else if builtins.pathExists (path + "/system-configuration.nix") then
              loadSystemManager name (path + "/system-configuration.nix")
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
          else if x.value.class == "system-manager" then
            "systemConfigs"
          else if x.value.class == "robotnix" then
            "robotnixConfigurations"
          else if x.value.class == "nix-on-droid" then
            "nixOnDroidConfigurations"
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

      packageEntries =
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

      # See the comment in mkEachSystem
      unfilteredPackages = lib.traceIf (builtins.pathExists (
        src + "/pkgs"
      )) "blueprint: the /pkgs folder is now /packages" (eachSystem ({ pkgs, ... }: mkPackagesFor pkgs));

      /**
        Load the `packages/` tree against a given nixpkgs instance.

        Packages get the same scope arguments as via `systemArgs` (`pkgs`,
        `flake`, `inputs`, `system`, `perSystem`, `pname`). `perSystem.self`
        resolves within this scope so intra-set references stay consistent
        with the supplied nixpkgs.

        Used internally for `packages.<system>` (with Blueprint's own `pkgs`)
        and exposed so consumers can build an overlay that uses their `pkgs`
        instead.

        # Type

        ```
        mkPackagesFor :: AttrSet -> AttrSet
        ```

        # Arguments

        pkgs
        : The nixpkgs instance to build the packages against.
      */
      mkPackagesFor =
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          scope = lib.makeScope lib.callPackageWith (self: {
            inherit
              inputs
              flake
              pkgs
              system
              ;
            perSystem = mkPerSystem {
              inherit inputs system;
              selfPackages = self.packageSet;
            };
            # NB: lib.makeScope reserves `packages` for its generator
            # function, so the result lives under a different name.
            packageSet = lib.mapAttrs (
              pname: { path, ... }: self.newScope { inherit pname; } path { }
            ) packageEntries;
          });
        in
        scope.packageSet;
    in
    # FIXME: maybe there are two layers to this. The blueprint, and then the mapping to flake outputs.
    {
      formatter = eachSystem (
        { pkgs, perSystem, ... }:
        perSystem.self.formatter or pkgs.nixfmt-tree
      );

      lib = tryImport (src + "/lib") specialArgs;

      # expose the functor to the top-level
      # FIXME: only if it exists
      __functor = x: inputs.self.lib.__functor x;

      devShells =
        let
          namedNix = (
            optionalPathAttrs (src + "/devshells") (
              path:
              (importDir path (
                entries:
                eachSystem (
                  { newScope, ... }:
                  lib.mapAttrs (pname: { path, type }: newScope { inherit pname; } path { }) (
                    lib.filterAttrs (
                      _name:
                      { path, type }:
                      type == "regular" || (type == "directory" && lib.pathExists "${path}/default.nix")
                    ) entries
                  )
                )
              ))
            )
          );

          namedToml = (
            optionalPathAttrs (src + "/devshells") (
              path:
              (importTomlFilesAt path (
                entries:
                eachSystem (
                  { newScope, perSystem, ... }:
                  lib.mapAttrs (
                    pname: { path, type }: newScope { inherit pname; } (_: devshellFromTOML perSystem path) { }
                  ) entries
                )
              ))
            )
          );

          defaultNix = (
            optionalPathAttrs (src + "/devshell.nix") (
              path:
              eachSystem (
                { newScope, ... }:
                {
                  default = newScope { pname = "default"; } path { };
                }
              )
            )
          );

          defaultToml = (
            optionalPathAttrs (src + "/devshell.toml") (
              path:
              eachSystem (
                { newScope, perSystem, ... }:
                {
                  default = newScope { pname = "default"; } (_: devshellFromTOML perSystem path) { };
                }
              )
            )
          );

          merge =
            prev: item:
            let
              systems = lib.attrNames (prev // item);
              mergeSystem = system: { ${system} = (prev.${system} or { }) // (item.${system} or { }); };
              mergedSystems = builtins.map mergeSystem systems;
            in
            lib.mergeAttrsList mergedSystems;
        in
        lib.foldl merge { } [
          namedToml
          namedNix
          defaultToml
          defaultNix
        ];

      # See the comment in mkEachSystem
      packages = lib.mapAttrs filterPlatforms unfilteredPackages;

      inherit mkPackagesFor;

      # Defining homeConfigurations under legacyPackages allows the home-manager CLI
      # to automatically detect the right output for the current system without
      # either manually defining the pkgs set (requires explicit system) or breaking
      # nix3 CLI output (`packages` output expects flat attrset)
      # FIXME: Find another way to make this work without introducing legacyPackages.
      #        May involve changing upstream home-manager.
      legacyPackages = lib.optionalAttrs (homesNested != { }) standaloneHomeConfigurations;

      darwinConfigurations = lib.mapAttrs (_: x: x.value) (hostsByCategory.darwinConfigurations or { });
      nixosConfigurations = lib.mapAttrs (_: x: x.value) (hostsByCategory.nixosConfigurations or { });
      systemConfigs = lib.mapAttrs (_: x: x.value) (hostsByCategory.systemConfigs or { });
      robotnixConfigurations = lib.mapAttrs (_: x: x.value) (
        hostsByCategory.robotnixConfigurations or { }
      );
      nixOnDroidConfigurations = lib.mapAttrs (_: x: x.value) (
        hostsByCategory.nixOnDroidConfigurations or { }
      );

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
                lib.filterAttrs (_: x: x.pkgs.stdenv.hostPlatform.system == system) (
                  inputs.self.nixosConfigurations or { }
                )
              )
            ))
            # add darwin system closures to checks
            (withPrefix "darwin-" (
              lib.mapAttrs (_: x: x.system) (
                lib.filterAttrs (_: x: x.pkgs.stdenv.hostPlatform.system == system) (
                  inputs.self.darwinConfigurations or { }
                )
              )
            ))
            # add system-manager closures to checks
            (withPrefix "system-" (
              lib.mapAttrs (_: x: x) (
                lib.filterAttrs (_: x: x.system == system) (inputs.self.systemConfigs or { })
              )
            ))
            # load checks from the /checks folder. Those take precedence over the others.
            (filterPlatforms system (
              optionalPathAttrs (src + "/checks") (
                path:
                let
                  importChecksFn = lib.mapAttrs (
                    pname: { type, path }: import path (systemArgs.${system} // { inherit pname; })
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

  /**
    Create a new Blueprint flake.

    This is the main entry point for consumers. It takes the project inputs,
    an optional `prefix` under which the Blueprint folder structure lives,
    nixpkgs configuration and a list of systems, and returns the generated
    flake outputs.

    # Type

    ```
    mkBlueprint :: {
      inputs :: AttrSet,
      prefix :: Path | String | null,
      nixpkgs :: { config :: AttrSet; overlays :: [ Overlay ]; },
      systems :: [ String ] | Path,
    } -> AttrSet
    ```

    # Arguments

    inputs
    : The flake inputs. `inputs.self` is the flake being built.

    prefix
    : Optional sub-directory under `inputs.self` where the Blueprint
      structure lives. Can be `null`, a `Path`, or a `String`.

    nixpkgs
    : nixpkgs configuration (`config` and/or `overlays`).

    systems
    : List of supported systems, or a path to a nix-systems file.
  */
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

  /**
    Make `lib.blueprint` callable as a function.

    Calling `inputs.blueprint { inherit inputs; }` is equivalent to
    `inputs.blueprint.lib.mkBlueprint { inherit inputs; }`.
  */
  __functor = _: mkBlueprint;
}
