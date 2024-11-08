#!/bin/bash          

# Installs SentinelOne standalone EDR for Macos
# token from your SentinelOne console is required.
# last test on Sequoia 15.1

# For debugging purposes, this script logs its activity to /tmp/SentinelOneInstaller.log

installToken="TOKEN FROM S1 PORTAL"

installerPKG= link with .pkg extension required for its operation

logFile="/tmp/SentinelOneInstaller.log"


if ! [ -f "$logFile" ]
then
	touch "$logFile"
fi

logToFile(){
	echo "" >> $logFile
	echo "[$(date)] $*" >> $logFile
}


logToFile "======== START ========"

# Check if S1 is already installed?

logToFile "Check if S1 is already installed?"

[[ -f /usr/local/bin/sentinelctl ]] && echo "SentinelOne already installed." && exit 1001


if [ -n "$1" ] # command line parameter
then
	logToFile "using install token $1"
    installToken=$1
fi

logToFile "cd to /tmp"
cd "/tmp/" || exit 1002

# create the token file if not already
logToFile "creating token file"
touch com.sentinelone.registration-token || exit 1003

# put the token into the file
logToFile "put the token into the file"
echo "$installToken" > com.sentinelone.registration-token

#Get Package Download

echo "Downloading SentinelOne Installer from ${installerPKG}"
logToFile "Downloading SentinelOne Installer from ${installerPKG}"
if curl -sSL -o "${TMPDIR}Sentinel.pkg" "${installerPKG}"
then
	#Install Package
	echo "Installing SentinelOne from ${TMPDIR}Sentinel.pkg"
	logToFile "Installing SentinelOne from ${TMPDIR}Sentinel.pkg"

	/usr/sbin/installer -allowUntrusted -verboseR -pkg "${TMPDIR}Sentinel.pkg" -target /

	exitcode=0
	
	# Check S1 has Full Disk Access?
	logToFile "Check S1 has Full Disk Access?"
	StatusMessage=$(/usr/local/bin/sentinelctl status --filters agent | grep "Missing")
	
	MissingAuths="*Missing*com.sentinelone*"

	while IFS= read -r StatusLine
	do
		if [[ "$StatusLine" =~ $MissingAuths ]]
		then		
			logToFile "[ WARNING ] SentinelOne missing Full Disk Access permissions."
			echo "[ WARNING ] SentinelOne missing Full Disk Access permissions."
			exitcode=1005
		else 
			logToFile "SentinelOne seems to have proper permissions. Continuing."
		fi
done <<-EOF
$StatusMessage
EOF
	logToFile "$exitcode"
	
	logToFile "======== DONE ========"
	

	exit $exitcode
	
else
	logToFile "Something went wrong downloading $installerPKG"
	echo "Something went wrong downloading $installerPKG"
	exit 1004
fi
