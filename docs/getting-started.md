# Getting started

1. Install [Nix](https://nix.dev/install-nix).
2. Run `mkdir my-project && cd my-project`
3. Run `nix flake init -t github:numtide/blueprint`.

This will give you a barebone project structure with a single `flake.nix` file containing the following content:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
```

From that point you won't have to touch this file (unless you're adding new inputs).

The rest happens in the [folder structure](folder-structure.md).

## Adding a host

TODO

## Adding a package

TODO
