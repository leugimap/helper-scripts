#!/bin/bash
# This script installs/reinstalls the latest Eric 6 on the user's home.
# No changes to the core system will be performed by the script.
#
# It allows Eric's uninstall script to work on some versions of Debian/Ubuntu where
# otherwise it would fail if run from recent versions of gnome-terminal (as Ubuntu 16.04 LTS)

echo "Getting latest version number"
LATEST_VERSION=$(wget --quiet -O - "http://eric-ide.python-projects.org/versions/versions6" | head -n1 | tr -d '\r' )
[ $? -ne 0 ] && echo "*** Error getting latest version" && exit 1
echo "Latest version is ${LATEST_VERSION}"
URL="https://sourceforge.net/projects/eric-ide/files/eric6/stable/${LATEST_VERSION}/eric6-${LATEST_VERSION}.tar.gz/download"

ERIC_INSTALL=${ERIC_INSTALL:-${HOME}/eric6-latest}
if [ -d $ERIC_INSTALL ]; 
then
  echo
  echo "Uninstalling previously installed instance at ${ERIC_INSTALL}"
  if [ -f  ${ERIC_INSTALL}/venv/bin/activate ];
  then
    source $ERIC_INSTALL/venv/bin/activate
    python -c 'import os; os.getlogin()' 2>/dev/null
    if [ $? -ne 0 ];
    then
        # This is needed for compatibility with gnome-terminal which has dropped utmp support in recent versions
        # which causes uninstall.py to crash as it relies on os.getlogin that reads from the utmp registry
        echo
        echo "Warning: Eric's uninstall script is not compatible with your terminal application."
        echo "You might need to type your password to try a workaround which requires sudo access,"
        echo "or alternatively press Ctrl-C to exit and then run this script from a different terminal app."
        PTY=$(ps ax | grep $$ | grep -v grep | awk '{print $2}')
        sudo sessreg -a -u /var/run/utmp -l $PTY $USER
    fi
    python $ERIC_INSTALL/uninstall.py
    if [ -n "$PTY" ];
    then
        sudo sessreg -d -u /var/run/utmp -l $PTY $USER
    fi
    deactivate
    rm -rf ${ERIC_INSTALL}/venv
    [ -f ${HOME}/.local/share/applications/latest-eric6.desktop ] && rm ${HOME}/.local/share/applications/latest-eric6.desktop
  else
    echo "No virtualenv found at ${ERIC_INSTALL}/venv (uninstall skipped)"
  fi
fi

echo
echo "Creating virtual environment in ${ERIC_INSTALL}/venv"
which virtualenv > /dev/null
if [ $? -ne 0 ];
then
  echo "*** Error: virtualenv cannot be found. Please install it and try again."
  echo "*** To install it in Debian/Ubuntu run:"
  echo "sudo apt install virtualenv"
  exit 1
fi

mkdir -p ${ERIC_INSTALL}
mkdir -p ${HOME}/bin
virtualenv -p python3 ${ERIC_INSTALL}/venv
[ $? -ne 0 ] && echo "*** Error: Creation of virtualenv in ${ERIC_INSTALL}/venv failed" && exit 1

echo
echo "Installing dependencies in local virtualenv"
source ${ERIC_INSTALL}/venv/bin/activate
pip install pyqt5 qscintilla
[ $? -ne 0 ] && echo "*** Error when installing requirements in virtualenv" && exit 1
if [ -n "$EXTRA_PIP" ];
then
    pip install $EXTRA_PIP
    [ $? -ne 0 ] && echo "*** Error installing extra requirements in virtualenv: $EXTRA_PIP." && exit 1
fi

echo
echo "Downloading bundle to /tmp/eric6-${LATEST_VERSION}.tar.gz"
wget --quiet --show-progress -N --trust-server-names --directory-prefix=/tmp "${URL}"
tar -zxf /tmp/eric6-${LATEST_VERSION}.tar.gz -C "${ERIC_INSTALL}" --strip-components 1 --overwrite
[ $? -ne 0 ] && echo "*** Error downloading and extracting bundle" && exit 1

echo
echo "Installing Eric ${LATEST_VERSION}"
python ${ERIC_INSTALL}/install.py -b ${HOME}/bin
[ $? -ne 0 ] && echo "*** Error during Eric installation process" && exit 1

deactivate

echo
echo "Creating application for Launcher"
mkdir -p ${HOME}/.local/share/applications/
cat > ${HOME}/.local/share/applications/latest-eric6.desktop << DESKTOPFILE
[Desktop Entry]
Comment=Custom install of latest Eric6
Terminal=false
Name=Eric6 (latest)
Exec=eric6 %F
Type=Application
MimeType=text/x-python;
Icon=${ERIC_INSTALL}/eric/icons/default/eric.png
Categories=Development;IDE;
StartupNotify=true
DESKTOPFILE

echo
echo "Eric6 installation complete!"
echo "You can either type eric6 in Unity/Gnome launcher or inside a terminal to run the IDE."
