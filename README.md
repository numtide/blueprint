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

blueprint is an opinionated library that maps a standard folder structure to flake outputs, allowing you to divide up your flake into individual files across these folders. This allows you to modularize and isolate these files so that they can be maintained individually and even shared across multiple projects. 

Blueprint also  makes common use cases easy for both the author and consumers.

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
* nix-darwin
* home-manager
* system-manager
* nix-unit
* default RFC166 nix formatter with `nix fmt`
* supports overridable systems with [nix-systems](https://github.com/nix-systems).
* automatic flake checks from packages, devshells and NixOS configurations.

and more!

## Rationale

Nix is just a tool. It should help you, and stay out of the way. But because it's so flexible, everybody goes through a long period where they figure out how to structure their repo. `flake.nix` files become noisy with boilerplate.

By making a few opinionated choices, we're able to cut 99% of the glue code you would find in most repos. A bit like Ruby on Rails or NextJS did for web frameworks, we do it for Nix packages. We map folder and files to flake outputs.

In some ways, this is the spiritual successor to `flake-utils`, my first attempt at making flakes easier to use.

Blueprint isn't suitable for complex flakes but it does allow you to easily break out once your project becomes complicated beyond its capability.

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

## Full Documentation

You can find the [full documentation here](https://numtide.github.io/blueprint/main/).

## Quickstart

Meanwhile, if you're ready to get started right away, here's what you do.

1. [Install Nix](https://nix.dev/install-nix) or use NixOS.
2. Run `mkdir my-project && cd my-project`
3. Run `nix flake init -t github:numtide/blueprint`.

Now you're ready to create some folders and special files. The full documentation shows you all the folders and special files available, but for now let's create a couple of development shells, and a formatter. 

Remember, the goal is to divide up the flake.nix file into individual modular parts. This not only helps keep your flake.nix file size down, it lets you create reusable modules that you can easily drop into other projects.

Let's create a package the builds a docker container from our source, assuming your source lives in a folder called src off the root folder. Assume your src entry point is a file called hello.py; in this example, just put the following in hello.py:

```
print('Hello from docker!')
```

Also from the root folder create a folder called packages, and under that a folder called `pkgs/docker-python-hello`. Inside that folder create a file called default.nix, and place the following in it:

```nix
{ pkgs, system, ... }:

let
  python = pkgs.python3;

  pythonApp = pkgs.stdenv.mkDerivation {
    pname = "my-python-app";
    version = "1.0";
    src = ../../src;

    installPhase = ''
      mkdir -p $out/app
      cp hello.py $out/app/
    '';
  };

  rootImage = pkgs.buildEnv {
    name = "my-docker-root";
    paths = [ python pythonApp ];
    pathsToLink = [ "/bin" "/app" ];  # python will be linked in /bin
  };
in
pkgs.dockerTools.buildImage {
  name = "my-python-hello";
  tag = "latest";

  fromImage = pkgs.dockerTools.pullImage {
    imageName = "python";
    finalImageTag = "3.11-slim";
    imageDigest = "sha256:7029b00486ac40bed03e36775b864d3f3d39dcbdf19cd45e6a52d541e6c178f0";
    sha256 = "sha256-lUrhG5Omgdk81NmQwQTo4wnEfq2+r2nGePpgTSYgVU0=";
  };

  copyToRoot = rootImage;

  config = {
    WorkingDir = "/app";
    Cmd = [ "python" "/app/hello.py" ];  # will now work since python is in /bin
  };
}
```

This will build an image into a folder called results; to do so, type the following:

```
nix build .#docker-python-hello
```

Note that the name to use must match the name of the folder under the packages folder.

Also notice that nix is able to find the default.nix file thanks to Blueprint. You can then load the image and run it by typing:

```
docker load < result
docker run --rm my-python-hello:latest
```

This should print the message:

```
Hello from docker!
```

Note that result is really a symbolic link to a tar.gz file containing the image in the store.

You can view your image by typing the usual:

```
docker images
```


