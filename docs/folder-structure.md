# Folder structure

## High-level

* `devshell.nix` for your developer shell.
* `hosts/` for machine configurations.
* `lib/` for Nix functions.
* `modules/` for NixOS and other modules.
* `pkgs/` for packages. 
* `templates/` for flake templates.

## File arguments

Each file typically gets passed a number of arguments.

### per-system

Some of the files are instantiated multiple times, once per configured system. See [configuration](configuration.md) on how the list of systems is defined.

Those take the following arguments:

* `inputs`: maps to the flake inputs.
* `system`: the current system attribute.
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.
* `flake`: points to the current flake. It's a shorthand for `inputs.self`.
* `pkgs`: and instance of nixpkgs, see [configuration](configuration.md) on how it's configured.

## Mapping

### `devshell.nix`

Contains the developer shell if specified.

Called with the [per-system](#per-system) attributes.

Flake outputs:
* `devShells.<system>.default`
* `checks.<system>.devshell`

#### Example

```nix
{ pkgs, perSystem, ... }:
pkgs.mkShell {
  packages = [
    perSystem.blueprint.default
    pkgs.terraform
  ];
}
```

### `hosts/<hostname>/(configuration.nix|darwin-configuration.nix)` 

Each folder contains either a NixOS or nix-darwin configuration:

#### `configuration.nix`

Evaluates to a NixOS configuration.

Additional values passed:
* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.

Flake outputs:
* `nixosConfigurations.<hostname>`
* `checks.<system>.nixos-<hostname>` - contains the system closure.

##### Example

```nix
{ flake, inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    flake.modules.nixos.server
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "24.05";
}
```

#### `darwin-configuration.nix`

Evaluates to a [nix-darwin](https://github.com/LnL7/nix-darwin) configuration.

To support it, also add the following lines to the `flake.nix` file:
```nix
{
  inputs.nix-darwin.url = "github:LnL7/nix-darwin";
}
```

Additional values passed:
* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.

Flake outputs:
* `darwinConfiguration.<hostname>`
* `checks.<system>.darwin-<hostname>` - contains the system closure.

### `lib/`

TODO

### `modules/<type>/(<name>|<name>.nix)`

Where the type can be:

* "nixos" → `nixosModules.<name>`
* "darwin" → `darwinModules.<name>`

These and other unrecognized types also make to `modules.<type>.<name>`.

### `packages/<pname>/(default.nix|package.nix)`

This folder contains all your packages.

Flake outputs:
* `packages.<system>.<pname>` - will contain the package
* `checks.<system>.pkgs-<pname>` - also contains the package for `nix flake check`.
* `checks.<system>.pkgs-<pname>-<tname>` - adds all the package `passthru.tests`

#### `default.nix`

Takes the "per-system" arguments. On top of this, it also takes a `pname`
argument.

#### `package.nix`

Use this when copying packages from `nixpkgs/pkgs/by-name`. `pkgs.callPackage` is called onto it.

#### `templates/<name>/`

Use this if you want your project to be initializable using `nix flake init`.

This is what is used by blueprint in the [getting started](getting-started.md) section.

If no name is passed, it will look for the "default" folder.

Flake outputs:
* `templates.<name>`
