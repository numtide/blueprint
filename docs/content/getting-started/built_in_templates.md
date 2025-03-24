# Using Templates

Blueprint comes with several templates to help you get started with your project.

> Note: We are continuing to add additional templates. Please check back periodically.

To install from a template, specify the template name after the initial flake init 
command, preceded by a hash symbol. For example, to use the template called system 
manager, type:

```
nix flake init -t github:numtide/blueprint#system-manager
```

## Default Template

Init command:

```bash
nix flake init -t github:numtide/blueprint
```

This is a bare-bones project as described in [getting started](../getting-started/install.md).

## NixOS and Darwin Shared Homes Template

```
nix flake init -t github:numtide/blueprint#nixos-and-darwin-shared-homes
```

This template is a bit of an example plus a template. You'll want to study all the
files carefully. It shows how you can define and reuse modules, in this case nixos
and home-manager.

Look carefully at the folder structure; in this case we're using `hosts` and
`modules` folders which are both picked up by Blueprint.

If you drill down into the folders, you'll see inside the `hosts` folder, are a
`my-darwin` folder and a `my-nixos` folder, both of which are imported by Blueprint.
This defines the two hosts called `my-darwin` and `my-nixos`.

Their respective configuration files both import a shared 
`modules/nixos/host-shared.nix` module between them.

Also, both hosts define a `me` user and their home-managed configuration
simply imports `modules/homes/home-shared.nix`.

Finally, notice in the root flake.nix we're adding the home-manager and nix-darwin 
inputs, which serve as dependencies for managing home configurations and macOS 
integrations, respectively.

The idea with this template is that you can use this example to get started on
how to share configurations between different system and home environments on different hosts.


## Toml-DevEnvs

```
nix flake init -t github:numtide/blueprint#toml-devenvs
```

When you run ```nix develop```, you'll be presented with a friendly message like so:

```
🔨 Welcome to devshell

[[general commands]]

  hello - Program that produces a familiar, friendly greeting
  menu  - prints this menu

[devshell]$
```

As you can see, this is quite different from just your average shell. It's highly 
configurable, and easy to configure using TOML files. [TOML files](https://en.wikipedia.org/wiki/TOML)
are a familiar way of storing configuration data. They support a natural way of 
expressing name-value pairs grouped into sections, such as the following:

```toml
[database]
server = "192.168.1.1"
ports = [ 8000, 8001, 8002 ]
connection_max = 5000
enabled = true
```

For more information, please visit our [devshell repo](https://github.com/numtide/devshell),
which is what powers this template behind-the-scenes.

## System Manager Template

```
nix flake init -t github:numtide/blueprint#system-manager
```

Notice that the root flake.nix file we're adding the system-manager input,
which is our own project. You can find it on GitHub at [system-manager](https://github.com/numtide/system-manager), where you can read more information on how
to use it.









