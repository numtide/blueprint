# blueprint - flakes made easy

> **STATUS: experimental**

## What's blueprint?

Blueprint replaces Nix glue code with a regular folder structure. Focus on deploying your infrastructure / package sets instead of reinventing the wheel.

The ambition is to handle all the workflows to reduce the cost of self-hosting infrastructure (we're not quite there yet).

## Getting started

Jump to [getting started](docs/getting-started.md).

## Rationale

Nix is just a tool. It should help you, and stay out of the way. But because
it's so flexible, everybody goes trough a 3 month period where they figure out
how to structure their home repo. `flake.nix` files all over the internet
become fatter and fatter with more glue code.

By making a few opinionated choices, we're able to cut 99% of the glue code
you would find in most repos. A bit like Ruby on Rails did for web frameworks,
we do it for Nix packages. We map folder and files to flake outputs.

In some ways, this is the spiritual successor to `flake-utils`, my first
attempt at making flakes easier to use.

What it's good for:

* Home and SME configurations
* Package sets

What it's bad for:

* Complicated setups (although we try to provide graceful fallback)
* Developer environments (see <https://devenv.sh>)

## Design principles

* User workflows come first.
* KISS. We don't need complicated module systems with infinite recursions.
* 1:1 mapping. Keep the mapping between attributes predictable.

## Features

* ./hosts for NixOS and Darwin configurations
* ./packages for your packages.
* ./lib for your libraries.
* ./templates for your flake templates.
* ./modules for common, nixos and darwin modules.
* ./devshell.nix for your developer env.
* default RFC166 nix formatter with `nix fmt`
* supports overridable systems with [nix-systems](https://github.com/nix-systems).
* automatic flake checks from packages, devshells and NixOS configurations.

and more!

## Related projects

* [flake-utils](https://github.com/numtide/flake-utils) the OG for flake libraries.
* [flake-parts](https://flake.parts) uses the Nix module system. It's too complicated for my taste.
* [std](https://github.com/divnix/std)
* [snowflake-lib](https://github.com/snowfallorg/lib)
* [clan-core](https://git.clan.lol/clan/clan-core) is an all-in-one solution to manage your deployments.
