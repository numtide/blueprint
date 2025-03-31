*[todo: We need to put together a short style guide for consistency, including*
* Nix (not nix)
* NixOS (not NixOs etc.) 
* Should we say "folder" or "directory"? Younger people seem to prefer "folder" ]

# Installing Blueprint

Let's create a small project with Nix, and you'll see how to add Blueprint to your project.

1. Install [Nix](https://nix.dev/install-nix).
2. Run `mkdir my-project && cd my-project`
3. Run `nix flake init -t github:numtide/blueprint`.

Note: After you install Nix, you'll need to enable "experimental features." Find out how here. [TODO: Let's write a blog post on how to enable experimental features on the different platforms. Googling doesn't bring up high-quality explanations.]

This will give you a barebone project structure with a single `flake.nix` file and a single `devshell.nix` file. (It also provides a basic .envrc, which lets you configure direnv [TODO: Move our direnv document to a blog post] and a starter .gitignore file. Make sure you're aware of this .gitignore file before you accidentally overwrite it.)

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

You create the folder structure based on the available list of folders [found here](folder_structure.md).

# A Sample Environment

Let's set up a development environment that includes:

* Python
* Python's numpy package

> **Tip:** In this section we'll be creating a default developer environment. You can also set up multiple developer environments and place them in the devshell folder as shown in the devshell section [here](folder_structure.md).

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

> **Tip:** It's often good practice to put the folder structure inside its own root folder. That way the folders will be grouped together and easy to distinguish from other folders. As an example, look at [NumTide treefmt](https://github.com/numtide/treefmt). 

Let's start with a root folder to hold the other folders. We'll use "nix" as that's the standard one we've created. Open up your root flake.nix file and expand the outputs line so it takes up multiple lines, and then add in the following prefix attribute:

```nix
  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "nix/";
    };
```

Now create a `nix` folder at the root of your project alongside the flake.nix and devshell.nix files.

Now you're ready to create some folders.

First, remember that folders are detected automatically by Blueprint. That way, you can drop in place pre-built packages. For example, on another project, you might have built a package that configures mysql. In that project you placed it in a folder called packages. You can then simply create a folder in your new project also called packages, and drop the mysql file in there, and you're good to go. No messing around with giant monolithic flake.nix file.

Let's do something similar. Let's add some documentation to your app. Suppose we want to set up MkDocs with your project.

> **Tip:** Remember, the whole point of Nix is to be able to set up reproducible environments. What that means is you don't need to install MkDocs globally. Instead, you can configure it directly in your project.

1. Under the `nix` folder, create another folder called `packages` (all lowercase).
2. Then under `packages` create a folder called `docs`.
3. Inside the `docs` folder, paste the following code into a file called `default.nix`:

```nix
{
  pkgs,
  perSystem,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "docs";

  unpackPhase = ''
    cp ${../../../mkdocs.yml} mkdocs.yaml
    cp -r ${../../../docs} docs
  '';

  nativeBuildInputs = with pkgs.python3Packages; [
    mike
    mkdocs
    mkdocs-material
    mkdocs-awesome-nav
  ];

  buildPhase = ''
    mkdocs build
  '';

  installPhase = ''
    mv site $out
  '';
}
```

> **Tip:** Because Blueprint is present, this code will get loaded automatically as needed. And notice how it can be reused; indeed for this example, we simply copied it over from the [Blueprint project itself](https://github.com/numtide/blueprint/blob/main/packages/docs/default.nix).

This code defines a derivation that builds the documentation. Before you can use it, however, you'll need some documentation. So again off the root folder of your project, create a folder called `docs`. This is where you'll put the documentation.

Inside the `docs` folder, create file called `index.md` and paste in perhaps the following:

```md
# Welcome to my amazing app!
We've built this amazing app and hope you enjoy it!
```

Next, we need a file that configures MkDocs called mkdocs.yml. In the root folder, create the file `mkdocs.yml` and paste the following in it:

```
site_name: AwesomeProject
```

Now let's build the docs using the mkdocs app. We'll build a static site. From your root folder, type:

```
nix build .#docs
```

You'll see a `results` folder appear. This contains the output from the mkdocs, which is the built website.
If you want to run the built-in mkdocs server to try out your site, type:

```
nix develop .#docs
```

Notice by calling nix develop, we're entering a development shell. But that happens only after we run the derivation. The derivation will compile our documents into a static site again (if necessary) and make the mkdocs command available to us while in the shell.

Open up a browser and head to `http://127.0.0.1:8000/` and you should see the
documentation open with a header "Welcome to my amazing app!" and so on.

## What did this demonstrate?

Without Blueprint installed, you would have had to place the above default.nix file containing the mkdocs code inside your main flake.nix file, or link to it manually. But because of Blueprint, your setup will automatically scan a set of predetermined folders (including Packages) for files and find them automatically, making them available to use.

> **Tip:** If you want to see what folders are available, head over to our 
[folder strutures](folder_structure.md) documentation.


# (Optional) Configuring direnv

Included in the initial files created by Blueprint is a filed called .envrc. This file contains code to configure direnv, which allows you to enter a devshell simply by switching to the folder containing your project. That means you don't need to type `nix develop` after entering the folder. Then when you move up and out of the folder, you'll automatically exit the environment.

For more information on configuring this feature, check out our guide at [Configuring Direnv](../guides/configuring_direnv.md)
