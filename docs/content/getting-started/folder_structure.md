# Folder Structure

Here's a rundown of the options for your folders, followed by detailed explanations of each.

> **Tip:** We recommend using a [prefix](configuration.md) (usually `nix/`) that specifies a root folder that in turn holds these folders.

## High-level

* `checks/` for flake checks.
* `devshells/` for devshells.
* `hosts/` for machine configurations.
* `hosts/*/users/` for Home Manager configurations.
* `lib/` for Nix functions.
* `modules/` for NixOS and other modules.
* `packages/` for packages.
* `templates/` for flake templates.

* `devshell.nix` for the default devshell
* `formatter.nix` for the default formatter
* `package.nix` for the default package

## File arguments

Each file typically gets passed a number of arguments.

### per-system

Some of the files are instantiated multiple times, once per configured system. See [configuration](configuration.md) on how the list of systems is defined.

Those take the following arguments:

* `inputs`: maps to the flake inputs.
* `flake`: maps to the flake itself. It's a shorthand for `inputs.self`.
* `system`: the current system attribute.
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.
* `pkgs`: and instance of nixpkgs, see [configuration](configuration.md) on how it's configured.


## **flake.nix** for the default flake

This is the default flake.nix file. In general you won't need to modify this very much, 
except for some basic configurations (described [here](configuration.md)),
as you'll be putting your main configurations in their own nix files in their own folders
as described here in this document.

## **devshell.nix** for the default devshell

This file holds the configuration for the default devshell, which you can run by simply typing:

```
nix develop
```

(We provide an example in our [install guide](install.md).)


## **devshells/**

In addition to the default devshell.nix file, you can configure multiple devshells for different scenarios, such as one for a backend build and one for a frontend build. (See later in this doc for an example.) You can configure devshells through either .nix files or through .toml files.

`nix` files are expected to evaluate into a shell derivation, normally the result of calling `mkShell`.

There might be many different `mkShell` implementations, like the one present in `nixpkgs` or the one
from `numtide/devshell`, and perhaps others. The one you choose depends on the features you might want
to use in your environment, like service management, modularity, command menu, etc.


```nix
# devshell.nix
# Using mkShell from nixpkgs
{ pkgs, perSystem, ... }:
pkgs.mkShell {
  packages = [
    perSystem.blueprint.default
    pkgs.terraform
  ];
}
```

```nix
# devshell.nix
# Using mkShell from numtide/devshell
# You are expected to add inputs.devshell in your flake.
{ pkgs, perSystem, ... }:
perSystem.devshell.mkShell {

  imports = [
    # You might want to import other reusable modules
    (perSystem.devshell.importTOML ./devshell.toml)
  ];

  env = [
    # Add bin/ to the beginning of PATH
    { name = "PATH"; prefix = "bin"; }
  ];

  # terraform will be present in the environment menu.
  commands = [ { package = pkgs.terraform; } ];
}
```

#### TOML devshells

`toml` shells are loaded with [devshell](https://numtide.github.io/devshell) but you are required to add
`inputs.devshell` to your flake.

```toml
# devshell.toml

# see https://numtide.github.io/devshell/extending.html
imports = [ "./modules/common.toml" ]

[[commands]]
package = "dbmate"

[devshell]
packages = ["sops"]

[[env]]
name = "DB_PASS"
eval = "$(sops --config secrets/sops.yaml --decrypt secrets/db_pass)"

[serviceGroups.database]
description = "Runs a database in the backgroup"
[serviceGroups.database.services.postgres]
command = "postgres"
[serviceGroups.database.services.memcached]
command = "memcached"
```

## **hosts/** for machine configurations.

Nix runs on many different operating systems and architecture. When you create 
a flake, you can define what systems it can produce outputs for.

You can configure your project to work with different hosts, which are specific
computers or systems.

> **Note:** Whereas systems refer to operating systems running in conjunction
with a specific architecture, a host refer to specific, single machine (virtual
or physical) that runs Nix or NixOS.


## `hosts/<hostname>/(default.nix|configuration.nix|darwin-configuration.nix,system-configuration.nix)`

Each folder contains either a NixOS or nix-darwin configuration:

### `configuration.nix`

Evaluates to a NixOS configuration.

Additional values passed:

* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.

Flake outputs:

* `nixosConfigurations.<hostname>`
* `checks.<system>.nixos-<hostname>` - contains the system closure.

##### NixOS example

```nix
{ flake, inputs, perSystem, ... }:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    flake.modules.nixos.server
  ];

  environment.systemPackages = [
    perSystem.nixos-anywhere.default
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
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.

Flake outputs:

* `darwinConfiguration.<hostname>`
* `checks.<system>.darwin-<hostname>` - contains the system closure.

#### `system-configuration.nix`

Evaluates to a [system-manager](https://github.com/numtide/system-manager)
configuration.

To support it, also add the following lines to the `flake.nix` file:

```nix
{
  inputs.system-manager.url = "github:numtide/system-manager";
}
```

Additional values passed:

* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.

Flake outputs:

* `systemConfiguration.<hostname>`
* `checks.<system>.system-<hostname>` - contains the system closure.

#### `default.nix`

If present, this file takes precedence over `configuration.nix` and `darwin-configuration.nix` and is designed as an
escape hatch, allowing the user complete control over `nixosSystem` or `darwinSystem` calls.

```nix
{ flake, inputs, ... }:
{
  class = "nixos";

  value = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";
        ...
  };
}
```

Additional values passed:

* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.

Expected return value:

* `class` - type of system. Currently "nixos" or "nix-darwin".
* `value` - the evaluated system.

Flake outputs:

> Depending on the system type returned, the flake outputs will be the same as detailed for NixOS or Darwin above.

## `hosts/<hostname>/users/(<username>.nix|<username>/home-configuration.nix)`

Defines a configuration for a Home Manager user. Users can either be defined as a nix file or directory containing
a `home-configuration.nix` file.

Before using this mapping, add the `home-manager` input to your `flake.nix` file:

```nix
{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Additional values passed:

* `inputs` maps to the current flake inputs.
* `flake` maps to `inputs.self`.
* `perSystem`: contains the packages of all the inputs, filtered per system.
    Eg: `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.
* other provided module arguments.
    Eg: home-manager provides `osConfig`, the host nixos/nix-darwin configuration.

> The simplest way to have a common/shared user configuration between multiple systems is to create a
> module at `modules/home/<name>.nix` ([docs](#modulestypenamenamenix)), and import that module
> from `inputs.self.homeModules.<name>` for each user that should inherit it. This pattern makes
> it easy to apply system-specific customizations on top of a shared, generic configuration.
> An example of this setup is shown in the following template: `templates/nixos-and-darwin-shared-homes`.

#### NixOS and nix-darwin

If `home-manager` is an input to the flake, each host with any users defined will have the appropriate home-manager
module imported and each user created automatically.

The options `home-manager.useGlobalPkgs` and `home-manager.useUserPkgs` will default to true.

#### Standalone configurations

Users are also standalone Home Manager configurations. A user defined as `hosts/pc1/users/max.nix` can be
applied using the `home-manager` CLI as `.#max@pc1`. The output name can be elided entirely if the current username
and hostname match it, e.g. `home-manager switch --flake .` (note the lack of `#`).

Because the username is part of the path to the configuration, the `home.username` option will default to
this username. This can be overridden manually. Likewise, `home.homeDirectory` will be set by default based
on the username and operating system (`/Users/${username}` on macOS, `/home/${username}` on Linux).

## `lib/default.nix`

Loaded if it exists.

Inputs:

* `flake`
* `inputs`

Flake outputs:

* `lib` - contains the return value of `lib/default.nix`

Eg:

```nix
{ flake, inputs }:
{ }
```

## **hosts/*/users/** for Home Manager configurations.

## **lib/** for Nix functions.

## `modules/<type>/(<name>|<name>.nix)`

Where the type can be any folder name.

For the following folder names, we also map them to the following outputs:

* "darwin" → `darwinModules.<name>`
* "home" → `homeModules.<name>`
* "nixos" → `nixosModules.<name>`

These and other unrecognized types also exposed as `modules.<type>.<name>`.

If a module is wrapped in a function that accepts one (or more) of the following arguments:

* `flake`
* `inputs`

Then that function is called before exposing the module as an output.
This allows modules to refer to the flake where it is defined, while the module arguments refer to the flake where the module is consumed. Those can
be but do not need to be the same flake.

## `package.nix`, `formatter.nix`, `packages/<pname>(.nix|/default.nix)`

This `packages/` folder contains all your packages.

For single-package repositories, we also allow a top-level `package.nix` that
maps to the "default" package.

Inputs:

The [per-system](#per-system) values, plus the `pname` attribute.

Flake outputs:

* `packages.<system>.<pname>` - will contain the package
* `checks.<system>.pkgs-<pname>` - also contains the package for `nix flake check`.
* `checks.<system>.pkgs-<pname>-<tname>` - adds all the package `passthru.tests`

To consume a package inside a host from the same flake, `perSystem.self.<pname>`

#### `default.nix` or top-level `package.nix`

Takes the "per-system" arguments. On top of this, it also takes a `pname`
argument.

## `checks/<pname>(.nix|/default.nix)`

The `checks/` folder can be populated by packages that will be run when `nix flake checks` is invoked.

The flake checks are also populate by some of the other attributes, like `packages` and `hosts`.

Inputs:

* The [per-system](#per-system) values, plus the `pname` attribute.

Flake outputs:

* `checks.<system>.<pname>` - will contain the package

### `templates/<name>/`

Use this if you want your project to be initializable using `nix flake init`.

This is what is used by blueprint in the [getting started](getting-started.md) section.

If no name is passed, it will look for the "default" folder.

Flake outputs:

* `templates.<name> -> path`

# Example devshells

Because of the presence of Bluprint, nix files contained in these folders and their
subfolders are immediately available.

As an example, let's create two devshell setups and put them under the devshells folder.

1. Create a new Blueprint project by creating a new folder and typing `nix flake init -t github:numtide/blueprint`
2. Create a folder inside the project folder called `devshells` (all lowercase) by typing `mkdir devshells` (if one doesn't already exist).
3. Move to the packages folder can create two folders under it: `mkdir backend && mkdir frontend`.

Go into the backend folder, and create a file called `default.nix` and paste the following into it:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.nodejs_23
    pkgs.geany
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''
    export PS1="(backend) $PS1"
  '';
}
```

This code will create a devshell that includes node.js and the IDE called Geany. It also 
sets the prompt to show the word `(backend)` as a reminder you're working in the bakcend. 
You can use this devshell for backend development.

Now move over to the `frontend` folder. Create a file called `default.nix` and paste
the following into it:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.nodejs_23
    pkgs.geany
    pkgs.nodePackages."@angular/cli"
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''
    export PS1="(frontend) $PS1"
  '';
}
```

This is similar to the backend, but you'll notice it also includes the CLI tools for Angular
for frontend development. This code also sets the prompt to say `(frontend)` to remind
you you're working in the front end.

Save both files and move to the root folder of the project.

Now you can invoke either development shell by typing one of the following:

* `nix develop .#backend` to launch the back end shell
* `nix develop .#frontend` to launch the front end shell

