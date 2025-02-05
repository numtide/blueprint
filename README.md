<div align="center">

# blueprint

<img src="docs/blueprint.svg" height="150"/>

**Standard folder structure for Nix projects**

*A <a href="https://numtide.com/">numtide</a> project.*

<p>
<img alt="Static Badge" src="https://img.shields.io/badge/Status-experimental-orange">
<a href="https://app.element.io/#/room/#home:numtide.com"><img src="https://img.shields.io/badge/Support-%23numtide-blue"/></a>
</p>

</div>

blueprint is an opinionated library that maps a standard folder structure to
flake outputs. It makes common use cases easy both for the author and
consumers.

Eg:

| path | flake output |
|-------|------|
| devshells/ | `devShells.*` |
| hosts/ | `nixosConfiguration.*` and `darwinConfigurations.*` ... |
| modules/ | `nixosModules.*` and `darwinModules.*` ... |
| packages/ | `packages.*` |

## Features

Support for:

* devshell.nix for your developer env.
* NixOS
* Nix-darin
* home-manager
* nix-unit
* default RFC166 nix formatter with `nix fmt`
* supports overridable systems with [nix-systems](https://github.com/nix-systems).
* automatic flake checks from packages, devshells and NixOS configurations.

and more!

## Documentation

* [Getting started](docs/getting-started.md).
* [Configuring blueprint](docs/configuration.md)
* [Folder structure mapping](docs/folder-structure.md)

## Rationale

Nix is just a tool. It should help you, and stay out of the way. But because
it's so flexible, everybody goes through a long period where they figure out
how to structure their repo. `flake.nix` files become noisy with boilerplate.

By making a few opinionated choices, we're able to cut 99% of the glue code
you would find in most repos. A bit like Ruby on Rails or NextJS did for web
frameworks, we do it for Nix packages. We map folder and files to flake
outputs.

In some ways, this is the spiritual successor to `flake-utils`, my first
attempt at making flakes easier to use.

Blueprint isn't suitable for complex flakes but it does allow you to easily
break out once your project becomes complicated beyond its capability.

## Design principles

* User workflows come first.
* KISS. We don't need complicated module systems with infinite recursions.
* 1:1 mapping. Keep the mapping between attributes predictable.

## Related projects

* [flake-utils](https://github.com/numtide/flake-utils) the OG for flake libraries.
* [flake-parts](https://flake.parts) uses the Nix module system. It's too complicated for my taste.
* [std](https://github.com/divnix/std)
* [snowflake-lib](https://github.com/snowfallorg/lib)
* [clan-core](https://git.clan.lol/clan/clan-core) is an all-in-one solution to manage your deployments.
