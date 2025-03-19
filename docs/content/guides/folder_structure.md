# Folder Structure

Here's a rundown of the options for your folders.

> **Tip:** We recommend using a prefix (usually nix) that specifies a root
folder that in turn holds these folders.

* checks/ for flake checks.

* devshells/ for devshells.

* hosts/ for machine configurations.

* hosts/*/users/ for Home Manager configurations.

* lib/ for Nix functions.

* modules/ for NixOS and other modules.

* packages/ for packages.

* templates/ for flake templates.

* devshell.nix for the default devshell

* formatter.nix for the default formatter

* package.nix for the default package

Because of the presence of Bluprint, nix files contained in these folders and their
subfolders are immediately available.

As an example, let's create two devshell setups and put them under the packages folder.

1. Create a new Blueprint project by creating a new folder and typing `nix flake init -t github:numtide/blueprint`
2. Create a folder inside the project folder called `packages` (all lowercase) by typing `mkdir packages`.
3. Move to the packages folder can create two folders under it: `mkdir backend && mkdir frontend`.

Go into the backend folder, and create a file called `default.nix` and paste the following into it:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.nodejs_23
    pkgs.geany
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''
    export PS1="(backend) $PS1"
  '';
}
```

[TODO/HOLD -- I'm creating shells here and putting them in the packages folder; they should be in the devshells folder.]

This code will create a devshell that includes node.js and the IDE called Geany. It also 
sets the prompt to show the word `(backend)` as a reminder you're working in the bakcend. 
You can use this devshell for backend development.

Now move over to the `frontend` folder. Create a file called `default.nix` and paste
the following into it:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.nodejs_23
    pkgs.geany
    pkgs.nodePackages."@angular/cli"
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''
    export PS1="(frontend) $PS1"
  '';
}
```

This is similar to the backend, but you'll notice it also includes the CLI tools for Angular
for frontend development. This code also sets the prompt to say `(frontend)` to remind
you you're working in the front end.

Save both files and move to the root folder of the project.

Now you can invoke either development shell by typing one of the following:

* `nix develop .#backend` to launch the back end shell
* `nix develop .#frontend` to launch the front end shell

