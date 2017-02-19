#! /bin/sh

WS_VER="8.0.1"

WORKING_DIR=`pwd`

# Setup settings file
setup_file="/etc/Websense"

# Get Java home
expr="JavaHome="
line=`egrep $expr $setup_file`

# strip the data from the end of the expression/key name
WS_JAVA_HOME=`expr "$line" : "$expr\(.*\)"`

# Get Websense Home
expr1="InstallPath="
line1=`egrep $expr1 $setup_file`

# strip the data from the end of the expression/key name
WS_HOME=`expr "$line1" : "$expr1\(.*\)"`

export WS_JAVA_HOME

# get the OS type
OS_NAME=`uname`
BIN_PATH="$WS_HOME/uninstall/uninstall_websense"

chmod 744 $BIN_PATH

echo "Welcome to the Websense Web Protection Solutions v$WS_VER uninstaller."

# default to command line start but provide an 
# option for starting installer in GUI mode
if [ "$1" = "-g" ]; then
	$BIN_PATH
else
    $BIN_PATH -i console
fi

# wait for install process to end
wait $!
printf "\n\nUninstallation ends...\n"


if [ -f $WS_HOME/delete ]; then
    cd /
    rm -Rf $WS_HOME/uninstall  > /dev/null 2>&1
    rm -Rf $WS_HOME/Manager  > /dev/null 2>&1
    rm -Rf $WS_HOME/bin  > /dev/null 2>&1
    rm -Rf $WS_HOME/download  > /dev/null 2>&1
    rm -Rf $WS_HOME/Documentation  > /dev/null 2>&1
    rm -f $WS_HOME/delete  > /dev/null 2>&1
    rm -f $WS_HOME/stderrlog  > /dev/null 2>&1
    rm -f $WS_HOME/stdoutlog  > /dev/null 2>&1
    rmdir $WS_HOME  > /dev/null 2>&1
fi

