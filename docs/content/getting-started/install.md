*[todo: We need to put together a short style guide for consistency, including*
* Nix (not nix)
* NixOS (not NixOs etc.) 
* Should we say "folder" or "directory"? Younger people seem to prefer "folder" ]

# Installing Blueprint

Let's create a small project with Nix, and you'll see how to add Blueprint to your project.

1. Install [Nix](https://nix.dev/install-nix).
2. Run `mkdir my-project && cd my-project`
3. Run `nix flake init -t github:numtide/blueprint`.

Note: After you install Nix, you'll need to enable "experimental features." Find out how here.

This will give you a barebone project structure with a single `flake.nix` file and a single `devshell.nix` file. (It also provides a basic .envrc, which [TODO] and a starter .gitignore file. Make sure you're aware of this .gitignore file before you accidentally overwrite it.)

Normally, without Blueprint, you would typically include a devShell section inside your flake.nix file. In that scenario, when you want to start a new project with a similar toolset, you'll likely need to copy over the devShell section of your flake.nix file to the new project's flake.nix file. But by using Blueprint, we've split out the devShell into its own file, allowing you to simply copy the file over.

Here's the starting point of your devShell.nix file:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [ ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
```

In a moment we'll look at what you can do with this file. Meanwhile, here's the flake.nix file:

```
{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
```

You generally shouldn't have to modify this file (unless you're adding new inputs).

When you run a nix command (such as `nix develop`), this flake.nix file is evaluated and Nix loads the Blueprint into the Nix store and makes it available to your current session. Blueprint in turn allows you to read .nix files from multiple locations within your project, including:

* The devShell.nix file in the root of your project
* A folder structure

You create the folder structure based on the available list of folders (found here).

# A Sample Environment

Let's set up a development environment that includes:

* Python
* Python's numpy package

Open up the devshell.nix file in your favorite editor, and update it to look like this:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.python3
    pkgs.python3Packages.numpy
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''
    export PS1="(python numpy) $PS1"
  '';
}
```

Notice we added two packages, Python and the NumPy Python package.

We also added a line inside shellHook. (This line is not required, but it's handy, as it updates the prompt to let you know when you're inside a nix shell.)

Now let's hop into the developer shell by typing:

```bash
nix develop
```

After a short moment where Nix downloads the packages, you'll be inside the shell. To verify the packages were installed, type:

```bash
python
```

Then, inside python type:

```
import numpy
```

You shouldn't see any error.

That's it; go ahead and exit python by typing

```bash
quit()
```

When you're ready to exit the development shell, you can simply type:

```bash
exit
```

## What did this demonstrate? 

The above demonstrated that the devshell.nix file is now self-contained and can be used without having to add devshell code inside your flake.nix file.

There's much more, however, that you can do.

Check out:

* Examples (including the rest of our Python/NumPy example)
* Guides
* Contributing

# Adding folders

Next, we'll add some folders into your project to give you an idea of how the
folder system works.

Remember that folders are read automatically. That way, you can drop in 
place pre-built flakes. For example, on another project, you might have
built a flake that configures mysql. In that project you placed it in
a folder called packages. You can then simply create a folder in your new
project also called packages, and drop the mysql file in there, and you're
good to go. No messing around with giant monolithic flake.nix file.

So let's do exactly that. Except instead of creating a nix for MySQL,
we'll just create 


# (Optional) Configuring direnv

Included in the initial files created by Blueprint is a filed called .envrc. This file contains code to configure direnv, which allows you to enter a devshell simply by switching to the folder containing your project. That means you don't need to type `nix develop` after entering the folder. Then when you move up and out of the folder, you'll automatically exit the environment.

For more information on configuring this feature, check out our guide at [Configuring Direnv](../guides/configuring_direnv.md)


## Creating a root folder





## Adding a host

TODO

## Adding a package

TODO
