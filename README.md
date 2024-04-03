# blueprint - lean flake

> **STATUS: experimental**

> Are you tired of copy-pasting Nix code and gluing everything together by hand?

Nix is just a tool. It should help you, and stay out of the way. But because
it's so flexible, everybody goes trough a 3 month period where they figure out
how to structure their home repo. `flake.nix` files all over the internet
become fatter and fatter with more glue code.

By making a few opinionated choices, we're able to cut 99% of the glue code
you would find in most repos. A bit like Ruby on Rails did for web frameworks,
we do it for Nix packages.

In some ways, this is the spiritual successor to `flake-utils`, my first
attempt at making flakes easier to use.

What it's good for:
* Home and SME configurations
* Package sets

What it's bad for:
* Complicated setups (although we try to provide gracefull fallback)
* Developer environments (see devenv.sh)

## Design principles

* KISS. We don't need complicated module systems with infinite recursions.
* 1:1 mapping.
* Keep the mapping between attributes predictable.
* Think about user workflows.

## Features

* default formatter
* lib folder
* templates folder
* packages folder
* supports overridable systems (see nix-systems)
* default flake checks
* NixOS configurations
* NixOS modules
* Darwin modules

## TODO

* Darwin configurations
* Home configurations

* `bp` CLI to:
    * login Nix to github
    * add/remove inputs
    * update inputs
    * flatten inputs to automate the input follows

* GitHub Actions integration

## Blacklisted inputs

In order to avoid name clashes, avoid loading inputs with the following names:
* lib
* pname
* system
* pkgs

## Getting started

[$ ./example/flake.nix](./example/flake.nix)

```nix
{
  description = "my flake";

  # Add all your dependencies here
  inputs = {
    blueprint.url = "path:..";
  };

  # Keep the magic invocations to minimum.
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
```

## Packages folder

If the ./pkgs folder exists, load every sub-folder in it and map it to the `packages` output.

Each sub-folder should contain a `default.nix`, with the following function
signature:

* pname: name of the folder. Useful to inject back.
* all the inputs

## How to support overrides?

Don't

## How to support overlays?

Don't


## Related projects

* [flake-utils](https://github.com/numtide/flake-utils) the OG for flake libraries.
* [flake-utils-plus]() extending flake-utils with more stuff.
* [flake-parts](https://flake.parts) uses the Nix module system. It's too complicated for my taste.
* [std]() ??
* [snowflake-lib](TODO)

