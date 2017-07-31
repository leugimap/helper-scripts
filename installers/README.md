## install-eric-ide.sh

This script downloads the latest released version of Eric IDE and installs it in the user's home directory. The required dependencies are installed in a python virtual environment inside that directory. No software or libraries will be installed at a system level.

Running the script again, will uninstall the previously installed version and reinstall with the latest available version.

### Install directory

By default, it will be installed under a directory called `eric6-latest` in your home directory. You can change this directory by running the script as:
```
ERIC_INSTALL=$HOME/directory-name bash install-eric-ide.sh
```

### Extra packages

By default the script only installs the bare minimum required packages needed to run the IDE. If you want extra packages in the virtual environment, you can add them to a variable called EXTRA_PIP. E.g., in order to enable `.md` files preview, you would run:
```
EXTRA_PIP='docutils markdown' bash install-eric-ide.sh
```
