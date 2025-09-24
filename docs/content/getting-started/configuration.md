# Configuration

In this section we describe the blueprint configuration options:

* **prefix**: This lets you specify a directory to hold the folders other than the flake.nix location.
* **systems**: Defines which systems the project should be used and deployed on.
* **nixpkgs.config**: If set, Blueprint will create a new instance of nixpkgs for each system.
* **nixpkgs.overlays**: If set, blueprint will create a new instance of nixpkgs for each system.

These are available by changing the `flake.nix` output invocation with additional parameters.

Below we provide more detail on each, along with examples.

## prefix

Set this if you want to load the blueprint from a directory within the repository other than the flake location.

Default: "."

Type: string.

For example, add the following prefix line to your output invocation:

```nix
outputs = inputs:
  inputs.blueprint {
    inherit inputs;
    prefix = "nix/";
  };
```

Then, you can add a `nix` folder inside the same folder that holds your flake file, and place all your folders within this `nix` folder.

> **Tip:** Although you can choose any folder you like, we recommend the name "nix" for your folder, as this is becoming the defacto standard.

## systems

Defines for which systems the project should be used and deployed on.

Default: it will load the `inputs.systems` flake input, first from the current flake, and then fallback to the blueprint one. (see <https://github.com/nix-systems/default>).

Type: list of `<arch>-<kernel>` strings.

Example:

```nix
{
  outputs = inputs: inputs.blueprint {
    inherit inputs;
    systems = [ "aarch64-linux" "x86_64-linux" ];
  };
}
```

## nixpkgs.config

If set, blueprint will create a new instance of nixpkgs for each system, with the passed config.

Default: `inputs.nixpkgs.legacyPackages.<system>`.

Type: attrset.

For example, the following sets the allowUnfree attribute of nixpkgs.config to true:

```nix
{
  outputs = inputs: inputs.blueprint {
    inherit inputs;
    nixpkgs.config.allowUnfree = true;
  };
}
```

## nixpkgs.overlays

> NOTE: It's better to use `perSystem` composition style instead of overlays if you can.

If set, blueprint will create a new overlay with the passed config.

Type: list of functions.

Here's an example that creates a couple of overlays; the first ("otherflake") reuses an overlay defined in another flake, and the second, an inline overlay, defines an overlay that replaces the default git package with the smaller gitMinimal:

```nix
{
  outputs = inputs: inputs.blueprint {
    inherit inputs;
    nixpkgs.overlays = [
      inputs.otherflake.overlays.default
      (final: prev: {
        git = final.gitMinimal;
      })
    ];
  };
}
```
