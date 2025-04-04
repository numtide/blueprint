# Using Templates

Blueprint comes with several templates to help you get started with your project.

> Note: Feel free to contribute new templates!

To install from a template, use the following format; for example, to use the template called system manager, type:

```
nix flake init -t github:numtide/blueprint#system-manager
```

where we appended a hash symbol followed by the template name.

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

This template is a bit of an example plus a template. You'll want to study all the files carefully. It shows how you can define and reuse modules, in this case nixos and home-manager.

Look carefully at the folder structure; in this case we're using `hosts` and `modules` folders which are both picked up by Blueprint.

If you drill down into the folders, you'll see inside the `hosts` folder, are a `my-darwin` folder and a `my-nixos` folder, both of which are imported by Blueprint. This defines the two hosts called `my-darwin` and `my-nixos`.

Their respective configuration files both import a shared  `modules/nixos/host-shared.nix` module between them.

Also, both hosts define a `me` user and their home-manager configuration simply imports `modules/homes/home-shared.nix`.

Finally, notice in the root `flake.nix` we're adding the home-manager and nix-darwin inputs, which serve as dependencies for managing home configurations and macOS integrations, respectively.

The idea with this template is that you can use this example to get started on how to share configurations between different system and home environments on different hosts.


## Toml-DevEnvs

Members of your team might be intimidated by Nix and flake files, and prefer a more traditional method of configuring their devshells. As such, we provide full support for TOML files.

For more information, please visit our [devshell repo](https://github.com/numtide/devshell), which is what powers this template behind-the-scenes.

## System Manager Template

```
nix flake init -t github:numtide/blueprint#system-manager
```

Notice that the root flake.nix file we're adding the system-manager input, which is our own project. You can find it on GitHub at [system-manager](https://github.com/numtide/system-manager), where you can read more information on how to use it.

