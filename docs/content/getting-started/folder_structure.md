# Folder Structure

Here's a rundown of the options for your folders, followed by detailed explanations of each.

> **Tip:** We recommend using a [prefix](configuration.md) (usually `nix/`) that specifies a root folder that in turn holds these folders.

## High-level

* `devshell.nix` for the default devshell
* `formatter.nix` for the default formatter
* `package.nix` for the default package
* `checks/` for flake checks.
* `devshells/` for devshells.
* `hosts/` for machine configurations.
* `lib/` for Nix functions.
* `modules/` for NixOS and other modules.
* `packages/` for packages.
* `templates/` for flake templates.


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
* `pkgs`: an instance of nixpkgs, see [configuration](configuration.md) on how it's configured.


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

## **Hosts** for machine configurations

## `hosts/<hostname>/(default.nix|configuration.nix|darwin-configuration.nix,system-configuration.nix)`

Nix runs on many different operating systems and architecture. When you create 
a flake, you can define what systems it can produce outputs for.

You can configure your project to work with different hosts, which are specific
computers or systems.

> **Note:** Whereas systems refer to operating systems running in conjunction
with a specific architecture, a host refers to specific, single machine (virtual
or physical) that runs Nix or NixOS.

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

### `darwin-configuration.nix`

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

### `system-configuration.nix`

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

### `default.nix`

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

## **lib/** for Nix functions.

### `lib/default.nix`

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

## **`modules/`** for NixOS and other modules.

### `modules/<type>/(<name>|<name>.nix)`

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


## **`packages/`** for packages.

### `package.nix`, `formatter.nix`, `packages/<pname>(.nix|/default.nix)`

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

## **`checks/`** for flake checks.

### `checks/<pname>(.nix|/default.nix)`

The `checks/` folder can be populated by packages that will be run when `nix flake checks` is invoked.

The flake checks are also populate by some of the other attributes, like `packages` and `hosts`.

Inputs:

* The [per-system](#per-system) values, plus the `pname` attribute.

Flake outputs:

* `checks.<system>.<pname>` - will contain the package

## **`templates/`** for flake templates.

### `templates/<name>/`

Use this if you want your project to be initializable using `nix flake init`.

This is what is used by blueprint in the [install](install.md) section.

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

# Example Hosts and Modules

This example comes from one of our available templates called [NixOS and Darwin Shared Homes Template](./built_in_templates.md#nixos-and-darwin-shared-homes-template).

Here we create two Blueprint folders, hosts and modules with the following subfolders:

```
root folder
├── flake.nix
├── hosts
│   ├── my-darwin
│   │   ├── darwin-configuration.nix
│   │   └── users
│   │       └── me
│   │           └── home-configuration.nix
│   └── my-nixos
│       ├── configuration.nix
│       └── users
│           └── me
│               └── home-configuration.nix
├── modules
│   ├── home
│   │   └── home-shared.nix
│   └── nixos
│       └── host-shared.nix
└── README.md

```

If you run the above command, this is the set of files you'll get. Take a look at the difference between darwin-configuration.nix under hosts/my-darwin and configuration.nix under hosts/my-nixos.

# Example Checks

Let's look at how you can put individual tests in the checks folder.

Start by creating a new folder and initializing the Flake with Blueprint:

```
nix flake init -t github:numtide/blueprint
```

Then create a folder called src, and another folder next to it called checks.

In the src folder, create three python files:

1. main.py

```python
from utils import string_length

if __name__ == "__main__":
    test_str = "hello"
    print(f"Length of '{test_str}' is {string_length(test_str)}")
```

2. utils.py

```python
def string_length(s):
    return len(s)
```

(As you can see, we're keeping this incredibly simple for demonstration purposes.)

3. test_length.py

```python
from utils import string_length

def test_string_length():
    assert string_length("hello") == 5
    assert string_length("") == 0
    assert string_length("squirrel!") == 8
```

Next, in the checks folder, create a file called test.nix. (Really you can call it anything you want, as long as it has a nix extension.) And place the following in it:

```nix
{ pkgs, system, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [ pytest ]);
in
pkgs.runCommand "string-length-test"
  {
    buildInputs = [ pythonEnv ];
    src = ./../src;
  } ''
    cp -r $src/* .
    # Run pytest, save output to file
    if ! pytest > result.log 2>&1; then
      cat result.log >&2  # dump the error to stderr so nix shows it
      exit 1
    fi
    touch $out
  ''
```

Now run:

```
nix flake check
```

And your test will run. Because it's correct, you won't see any output. So perhaps try adjusting the function to make it purposely return the wrong number:

```python
def string_length(s):
    return len(s) + 1
```

Then when you run `nix flake check` you should see the output from the pytest tool.

> **Note:** You'll actually only see the last part of the output. At the bottom will be a message explaining how to view the full logs. It will be similar to this:
> 
> *For full logs, run 'nix log /nix/store/8qqfm9i0b3idljh1n14yqhc12c5dv8j2-string-length-test.drv'.*
> 

From there you can see the full output from pytest, including the assertion failures.
