# Configuring Direnv to speed up loading developer environments

Included in the initial files created by Blueprint is a filed called .envrc. This file contains code to configure direnv, which allows you to enter a devshell simply by switching to the folder containing your project. That means you don't need to type `nix develop` after entering the folder. Then when you move up and out of the folder, you'll automatically exit the environment.

## 1. Install direnv. If you're using NixOS:

In the bash shell, type:

```bash
cd /etc/nixos
```

Then open the file called `configuration.nix` using sudo in conjunction with your favorite editor. For example, if you're using vim:

```bash
sudo vi configuration.nix
```

Locate the line starting with `environment.systemPackages` and add the direnv package, similar to the following:

```bash
environment.systemPackages = with pkgs; [ vim git direnv ];
```

(In this example, I already had vim and git installed.)

## 2. Add a shell hook

Now return to your home folder and open .envrc:

```
cd ~
vi .bashrc
```

Add the following line to the end of the file:

```bash
eval "$(direnv hook bash)"
```

Save the file and exit. Then either:
* Log out and log back in or
* Run the same eval command manually to activate it

Now direnv is running. Switch to a folder containing a Flake/Blueprint project you previously created. For this example we'll use the one we created in the install page, which includes Python and Python's NumPy package.

```bash
cd python_numpy
```

Note that the first time you do this, you will encounter an error:

```bashrc
direnv: error /home/nixos/dev/python_numpy/.envrc is blocked. Run `direnv allow` to approve its content
```

Go ahead and type:

```bash
direnv allow
```

Then direnv will automatically launch the devshell for you. Try it! In this case, because we have Python and NumPy installed, type:

```bash
python
```

and a Python shell should open. Then type:

```python
import numpy
```

Press Enter and you'll see it loaded without an error. Type

```python
exit()
```

## 3. Updating devshell.nix

Direnv will automatically reload and relaunch your developer environemnt quietly behind the scenes if you update your devshell.nix file. Let's try it out. Let's add in the pandas library. 

First, verify that pandas is *not* installed. From within Python, try to import pandas; after the error message, exit out of Python:

```python
>>> import pandas
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ModuleNotFoundError: No module named 'pandas'
>>>
>>> exit()
```

Now open devshell.nix in your favorite editor, and add the pandas package:

```nix
{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.python3
    pkgs.python3Packages.numpy
    pkgs.python3Packages.pandas
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
```
Save it, and you'll briefly see direnv kick in and display some messages. Now return to Python and you'll see that you now have the Pandas package available.

```python
>>> import pandas
>>> 
>>> exit()
```

## 4. Exiting the development shell

Finally Now cd up and out of the current folder:

```bash
cd ...
```

You'll see the message:

```bash
direnv: unloading
```

And now to see that you've left the developer environment, try typing ```python``` again and you should see a ```command not found``` error.

