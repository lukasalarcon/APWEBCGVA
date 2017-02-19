#!/bin/sh
#
#################################
#                               #
#           Uninstall           #
#                               #
#################################

WCG_Version=8.0.1-1117
WCG_Version_Display="${WCG_Version}"

#----------------------------------------------------------------
#
# Include all shell routines for use in the install script
#
#----------------------------------------------------------------

# CheckPrevWCGInstall - check if previous install and/or
#                      running websense content gateway exist
#######################################################
CheckPrevWCGInstall() {
  if [ -f /etc/content_gateway ]; then
    # check the version number of the previous install
    OldInstDir=`${HEAD} -n 1 /etc/content_gateway`
    version_file=${OldInstDir}/config/internal/.WCG_version

    if [ -f ${version_file} ]; then
      VersionNumber=`${HEAD} -n 1 ${version_file} | ${AWK} '{print $2}'`
      TimeStamp=`date +%Y%m%d-%H%M%S`
    fi
  fi
}

# Usage - display the commandline option for the installation
#############################################################
Usage() {
  arg=$1
  if [ -z "${arg}" ]; then
    echo ""
    echo "Error(GEN): Invalid number of arguments."
  fi
  echo ""
  echo "Usage: ./wcg_uninstall.sh"
  echo ""
  exit
}

# SetGlobalVariables - set the OS dependent default variables
#############################################################
SetGlobalVariables() {
  # set path for system utilities
  PATH=/usr/bin:/bin:/sbin:/usr/sbin:/etc:/usr/ucb:/usr/bsd:/usr/etc:/usr/local/bin; export PATH
  # Get local host name
  Hostname=`(uname -n) 2>/dev/null` || Hostname=unknown
  # Identify operating system environment
  uname_processor=`(uname -p) 2>/dev/null` || uname_processor=unknown

  InstUser="root"
  HomeDir=`eval echo \~${InstUser}`

  LogFile="/tmp/WCGuninstall.log"      # default installation log file
  OldInstDir="NONE"                    # default old installation directory
  VersionNumber="unknown"              # default old installation version
  upgrade="false"                      # upgrade default to be false

  GetPath grep
  GREP=${cmd_path}
  GetPath awk
  AWK=${cmd_path}
  GetPath ps
  PS=${cmd_path}
  GetPath head
  HEAD=${cmd_path}
}

# GetYesNo - function to get yes/no responses from user
#            It will iteractively ask for yes/no answer if
#            user input isn't y/n or Y/N.
# $1 : message displayed before prompt for yes/no response
##########################################################
GetYesNo() {
# Answer read from user
_ANSWER=
  if [ $# -eq 0 ]; then
    echo "Usage: GetYesNo message [yes|no]" 1>&2
    exit 1
  fi
  while :
  do
    if [ "`echo -n`" = "-n" ]; then
      echo "$@\c" | tee -a $LogFile
    else
      echo -n "$@" | tee -a $LogFile
    fi
    read _ANSWER
    case "$_ANSWER" in
      [yY] | yes | YES | Yes)
        echo $_ANSWER >> $LogFile
        return 0
      ;;
      [nN] | no  | NO  | No )
        echo $_ANSWER >> $LogFile
        return 1
      ;;
      * ) echo "Please enter y or n." | tee -a $LogFile
      ;;
    esac
  done
}

# GetPath - routine to find out the absolute path of
#           shell build-in commands to avoid aliases
####################################################
GetPath() {
  cmd=$1
  cmd_path=`(which ${cmd}) 2>/dev/null`
  if [ $? -ne 0 ]; then
    cmd_path=$1
  fi
  wd_count=`echo "${cmd_path}" | wc -w 2>/dev/null`
  if [ $? -ne 0 -a ${wd_count} -ne 1 ]; then
    cmd_path=$1
  fi
}

# CheckWCGLock - make sure there isn't an installation underway
##########################################################
CheckWCGLock() {
  # Check for an installation underway.
  # exits if installation failed to cleanup.
  if [ -f /tmp/WCGinstlock ]; then
    echo ""              | tee -a $LogFile
    echo "Error(GEN): A Websense Content Gateway installation in progress." | tee -a $LogFile
    echo ""              | tee -a $LogFile
    echo "Please make sure there are no product installations" | tee -a $LogFile
    echo "in progress, and remove the file /tmp/WCGinstlock,"          | tee -a $LogFile
    echo "if necessary, before trying again." | tee -a $LogFile
    exit
  fi
}

# KillWebsenseContentGateway - stop any active Websense Content Gateway processes
##############################################################
KillWebsenseContentGateway() {
  WCGRunning=`${OldInstDir}/WCGAdmin status 2>/dev/null | grep . | grep -v NOT`
  if [ ! -f ${OldInstDir}/config/internal/no_cop -o ! -z "${WCGRunning}" ]; then  
    StoppedWCG="true"

    echo ""
    echo -n "Stopping Websense Content Gateway processes..." | tee -a $LogFile

    ${OldInstDir}/WCGAdmin stop >/dev/null 2>&1

    # check if websense content gateway is still running even after killing the WCG processes
    match=`${PS} -ef 2>/dev/null | ${GREP} content_cop | ${GREP} -v grep`
    if [ "${match}" ]; then
      echo ""             | tee -a $LogFile
      echo "Error(GEN): Unable to stop active Content Gateway processes on this system." | tee -a $LogFile
      echo ""             | tee -a $LogFile
      Unlock 8
    fi

    echo "done" | tee -a $LogFile
  fi
}

CacheUninstall() {
  rc_script=/etc/rc.d/init.d/content_gateway
  if [ -f ${rc_script} ]; then
    if [ -f /etc/udev/rules.d/60-raw.rules ]; then
      raw_disks=`cat ${rc_script} | ${GREP} "^/bin/raw" | ${AWK} '{print $2}'`
      storage_config=${OldInstDir}/config/storage.config
      if [ -f ${storage_config} ]; then
        cache_disks=`cat ${storage_config} | ${GREP} "^/etc/udev/devices" | ${AWK} '{print $1}'`
        for cache_disk in ${cache_disks}
        do
          echo "removing ${cache_disk}" >> $LogFile
          rm -f ${cache_disk} >/dev/null 2>&1
        done
      fi
    else
      raw_disks=`cat ${rc_script} | ${GREP} "^/usr/bin/raw" | ${AWK} '{print $2}'`
    fi
    
    for raw_disk in ${raw_disks}
    do
      echo "removing raw device ${raw_disk}" >> $LogFile
      rm -f ${raw_disk} >/dev/null 2>&1 
    done
  fi
}

SysResetEnvironment() {
  echo "Resetting Websense Content Gateway environment..." >> $LogFile

  profile=${HomeDir}/.profile
  bash_profile=${HomeDir}/.bash_profile
  cshrc=${HomeDir}/.cshrc

  # remove any WCGHome references or LD_LIB_PATH line containing /opt/WCG/lib. not needed anymore.
  if [ -f ${profile} ]; then
    sed -i -e "/WCGHome/d" ${profile}
    sed -i -e "/LD_LIBRARY_PATH.*\/opt\/WCG\/lib/d" ${profile}
  fi

  if [ -f ${bash_profile} ]; then
    sed -i -e "/WCGHome/d" ${bash_profile}
    sed -i -e "/LD_LIBRARY_PATH.*\/opt\/WCG\/lib/d" ${bash_profile}
  fi

  if [ -f ${cshrc} ]; then
    sed -i -e "/WCGHome/d" ${cshrc}
    sed -i -e "/LD_LIBRARY_PATH.*\/opt\/WCG\/lib/d" ${cshrc}
  fi
}

SysClearCronJob() {
  echo ""
  echo -n "Removing Websense Content Gateway cron jobs..."

  # Remove all WCG cron jobs
  rm -f /etc/cron.d/WCG_*
  
  echo "done" | tee -a $LogFile
}

SysResetBootScript() {
  if [ -f /etc/rc.d/init.d/WCG ]; then
    chkconfig --del WCG
    rm -f /etc/rc.d/init.d/WCG
    rm -f /var/lock/subsys/WCG
  fi
}

SystemUninstall() {
  SysResetEnvironment
  SysClearCronJob
  SysResetBootScript
}

ArmUninstall() {
  # remove ARM device
  if [ -e /dev/iparm ]; then
    /bin/rm -f /dev/iparm >> $LogFile 2>&1
  fi
  if [ -n "`lsmod | grep ip_gre`" ]
  then
    rmmod ip_gre
  fi
  if [ -n "`lsmod | grep ip_tunnel`" ]
  then
    rmmod ip_tunnel
  fi
}

SrvMgrUninstall() {
  if [ -x ${OldInstDir}/bin/WTGApp ]; then
    ${OldInstDir}/bin/WTGApp -u >> $LogFile 2>&1 &

    proc=`${PS} -ef | ${GREP} WTGApp | ${GREP} -v grep | ${AWK} '{print $2}'`
    count=0

    while [ ${count} -le 12 ] && [ ! -z "${proc}" ]; do
      sleep 1
      proc=`${PS} -ef | ${GREP} WTGApp | ${GREP} -v grep | ${AWK} '{print $2}'`
      count=`expr ${count} + 1`
    done

    if [ ! -z "${proc}" ]; then
      killall WTGApp >> $LogFile 2>&1
    fi
  else
    echo "ERROR: unable to remove entry from Server Manager" | tee -a $LogFile
  fi
}

SAMBAUninstall() {
  if ! ${OldInstDir}/contrib/samba/SMBAdmin uninstall >> $LogFile 2>&1 ; then
    echo "ERROR: unable to safely remove samba chroot filesystem mounts. Aborting." | tee -a $LogFile
    exit 1337
  fi
}

UninstallRPM() {
  rpm_vers=`rpm -qa | grep $1`

  if [ ! -z "${rpm_vers}" ]; then
    rpm -e ${rpm_vers} > /dev/null 2>&1
  fi
}

DSSUninstall() {
  echo ""
  echo -n "Uninstalling TRITON AP-DATA Policy Engine..." | tee -a $LogFile
  #install dir cant change. hardcode okay.
  /opt/websense/PolicyEngine/managePolicyEngine -command unregister > /dev/null 2>&1

  rpm_vers=`rpm -qa | grep PolicyEngine`

  if [ ! -z "${rpm_vers}" ]; then
    rpm -e ${rpm_vers} > /dev/null 2>&1

    if [ $? -eq 0 ]; then
      rm -rf /opt/websense/PolicyEngine
      echo "done" | tee -a $LogFile
    else
      echo "failed" | tee -a $LogFile
    fi
  fi

  if [ -e /opt/websense ]; then
    rm -rf /opt/websense
  fi
}

RPMUninstall() {
  echo ""
  echo -n "Uninstalling additional RPMs..." | tee -a $LogFile

  UninstallRPM python2.5-WS
  UninstallRPM ws-icu
  UninstallRPM ws-log4cxx
  UninstallRPM ws-xerces
  UninstallRPM wswd

  UninstallRPM perl-Crypt-Blowfish

  UninstallRPM wcg_deps
  UninstallRPM wcg_rh7_deps

  echo "done" | tee -a $LogFile
}

########################### Websense Content Gateway Uninstallation ###########################
PrintUninstallGreeting() {
  echo ""                                                          | tee -a $LogFile
  echo ""                                                          | tee -a $LogFile
  date >>$LogFile
  echo "#########################################################" | tee -a $LogFile
  echo "#"                                                         | tee -a $LogFile
  echo "#        Websense Content Gateway Uninstall"               | tee -a $LogFile
  echo "#        This will remove the Websense Content Gateway"    | tee -a $LogFile
  echo "#        on system ${Hostname}."                           | tee -a $LogFile
  echo "#"                                                         | tee -a $LogFile
  echo "#########################################################" | tee -a $LogFile
  echo ""                                                          | tee -a $LogFile
  echo ""                                                          | tee -a $LogFile
}

# UninstallProc - The uninstallation structure of the installer
#
#####################################################################
UninstallProc() {
  RemovedExisting="True"

  echo "" | tee -a $LogFile
  echo "Uninstalling Websense Content Gateway components..." | tee -a $LogFile

  if [ -e ${OldInstDir}/bin/arm_enable.sh ]; then
    ${OldInstDir}/bin/arm_enable.sh 0 >> $LogFile 2>&1
  fi

  if [ -d ${OldInstDir}/contrib/samba ] ; then
    SAMBAUninstall
  fi

  CacheUninstall

  SystemUninstall

  ArmUninstall

  if [ -d /opt/websense/PolicyEngine ] ; then
    DSSUninstall
  fi

  RPMUninstall

  rm -rf ${OldInstDir}

  rm -f /etc/content_gateway
  rm -f /var/lock/subsys/WCG
}

################
#     Main     #
################

# set values for global variables
SetGlobalVariables

# if no argument, default to interactive option
if [ $# -eq 0 ]; then
  arg_1="-u"
else
  arg_1=$1
fi

# check login -> only root can remove websense content gateway
if [ `whoami` != "root" ]; then
  echo ""
  echo "Error(GEN): Current user is not root."
  echo ""
  echo "You must uninstall Websense Content Gateway using the 'root' user account."
  echo "Login as the 'root' user, and retry."
fi

# handle argument checking for the uninstall script
case "$arg_1" in
  -upgrade)
    upgrade="true"
  ;;
  -u)
    CheckWCGLock
  ;;
  *)
    Usage
  ;;
esac

# check for the previous install
CheckPrevWCGInstall

if [ "${OldInstDir}" != "NONE" ]; then

  if [ "${upgrade}" != "true" ]; then

    PrintUninstallGreeting

    GetYesNo "Are you sure you want to remove Websense Content Gateway [y/n]? "

    if [ "$?" -ne 1 ]; then
      # Uninstall ourselves from Server Manager
      SrvMgrUninstall

      # kill any running websense content gateway
      KillWebsenseContentGateway

      UninstallProc

      echo ""
      echo "Completed Websense Content Gateway Uninstall." | tee -a $LogFile
      echo "" | tee -a $LogFile
    else
      echo ""
      echo "Websense Content Gateway Uninstall aborted by user." | tee -a $LogFile
      echo "" | tee -a $LogFile
    fi

  else
    UninstallProc
  fi

else
  echo "There is no Websense Content Gateway installed on this system." | tee -a $LogFile
  echo "" | tee -a $LogFile
fi
