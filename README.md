# blueprint - flakes made easy

> **STATUS: experimental**

## What's blueprint?

Blueprint is a light framework that replaces Nix glue code with a regular folder structure. Focus on deploying your infrastructure / package sets instead of reinventing the wheel.

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

-   Home and SME configurations
-   Package sets

What it's bad for:

-   Complicated setups (although we try to provide gracefull fallback)
-   Developer environments (see devenv.sh)

## Design principles

-   KISS. We don't need complicated module systems with infinite recursions.
-   1:1 mapping. Keep the mapping between attributes predictable.
-   Think about user workflows.

## Features

-   default formatter
-   lib folder
-   templates folder
-   packages folder
-   supports overridable systems (see nix-systems)
-   default flake checks
-   NixOS configurations
-   NixOS modules
-   Darwin modules
-   Darwin configurations
-   devshell

## Blacklisted inputs

In order to avoid name clashes, avoid loading inputs with the following names:

-   lib
-   pname
-   system
-   pkgs

## Packages folder

If the ./pkgs folder exists, load every sub-folder in it and map it to the `packages` output.

Each sub-folder should contain a `default.nix`, with the following function
signature:

-   pname: name of the folder. Useful to inject back.
-   all the inputs

## How to support overrides?

Don't

## How to support overlays?

Don't

## Related projects

-   [flake-utils](https://github.com/numtide/flake-utils) the OG for flake libraries.
-   [flake-utils-plus]() extending flake-utils with more stuff.
-   [flake-parts](https://flake.parts) uses the Nix module system. It's too complicated for my taste.
-   [std]() ??
-   [snowflake-lib](TODO)
