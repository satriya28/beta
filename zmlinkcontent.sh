#!/bin/bash
# The purpose of this file is to create the symlinks in the web folder to the content folder. It can use an existing content folder or create a new one.

# Set the content dir default to be the one supplied to cmake
ZM_PATH_CONTENT="/var/lib/zoneminder"

echo "*** This bash script creates the nessecary symlinks for the zoneminder content"
echo "*** It can use an existing content folder or create a new one"
echo "*** For usage: use -h"
echo "*** The default content directory is: $ZM_PATH_CONTENT"
echo ""

usage()
{
cat <<EOF
Usage: $0 [-q] [-z zm.conf] [-w WEB DIRECTORY] [CONTENT DIRECTORY]

OPTIONS:
   -h      Show this message and quit
   -z      ZoneMinder configuration file
   -w      Override the web directory from zm.conf
   -q      Quick mode. Do not change ownership recursively.

If the -w option is not used to specify the path to the web directory,
the script will use the path from zoneminder's configuration file.
If the -z option is used, the argument will be used instead of zm.conf
Otherwise, it will attempt to read zm.conf from the local directory.
If that fails, it will try from /etc/zm.conf

EOF
}

while getopts "hz:w:q" OPTION
do
     case $OPTION in
         h)
             usage
             exit 50
             ;;
         z)
             ZM_CONFIG=$OPTARG
             ;;
         w)
             ZM_PATH_WEB_FORCE=$OPTARG
             ;;
         q)
             QUICK=1
             ;;
     esac
done
shift $(( OPTIND - 1 ))

# Lets check that we are root
if [ "$(id -u)" != "0" ]; then
	echo "Error: This script needs to run as root."
	exit 1
fi

# Check if zm.conf was supplied as an argument and that it exists
if [[ -n "$ZM_CONFIG" && ! -f "$ZM_CONFIG" ]]; then
	echo "The zoneminder configuration file $ZM_CONFIG does not exist!"
	exit 40
fi

# Load zm.conf
if [ -n "$ZM_CONFIG" ]; then
	echo "Using custom zm.conf $ZM_CONFIG"
	source "$ZM_CONFIG"
elif [ -f "zm.conf" ]; then
	echo "Using local zm.conf"
	source "zm.conf"
elif [ -f "/etc/zm.conf" ]; then
	echo "Using system zm.conf"
	source "/etc/zm.conf"
else
	echo "Failed locating zoneminder configuration file (zm.conf)\nUse the -z option to specify the full path to the zoneminder configuration file"
	exit 45
fi

# Override the web directory path from zm.conf
if [ -n "$ZM_PATH_WEB_FORCE" ]; then
	ZM_PATH_WEB="$(readlink -f $ZM_PATH_WEB_FORCE)"
fi

# Override the default content path
if [[ -n "$@" ]]; then
	ZM_PATH_CONTENT="$(readlink -f $@)"
fi

# Print some information
echo "Web folder       : $ZM_PATH_WEB"
echo "Content folder   : $ZM_PATH_CONTENT"
echo ""

# Verify the web folder is a real directory
echo -n "Verifying the web folder is a directory... "
if [ -d "$ZM_PATH_WEB" ]; then
	echo "OK"
else
	echo "Failed"
	exit 3
fi

# Check if the content folder exists, and if not, create it
echo -n "Checking if the content folder exists... "
if [ -d "$ZM_PATH_CONTENT" ]; then
	echo "Yes"
else
	echo "No"
	echo -n "Creating the content folder... "
	mkdir "$ZM_PATH_CONTENT"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 4
	fi
fi
# Check if the content/images folder exists, and if not, create it
echo -n "Checking if the images folder exists inside the content folder... "
if [ -d "$ZM_PATH_CONTENT/images" ]; then
	echo "Yes"
else
	echo "No"
	echo -n "Creating the images folder inside the content folder... "
	mkdir "$ZM_PATH_CONTENT/images"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 6
	fi
fi
# Check if the content/events folder exists, and if not, create it
echo -n "Checking if the events folder exists inside the content folder... "
if [ -d "$ZM_PATH_CONTENT/events" ]; then
	echo "Yes"
else
	echo "No"
	echo -n "Creating the events folder inside the content folder... "
	mkdir "$ZM_PATH_CONTENT/events"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 7
	fi
fi

if [ -d "$ZM_PATH_WEB/images" ]; then
	if [ -L "$ZM_PATH_WEB/images" ]; then
		echo -n "Unlinking current symlink for the images folder... "
		unlink "$ZM_PATH_WEB/images"
		if [ "$?" = "0" ]; then
			echo "OK"
		else
			echo "Failed"
			exit 35
		fi
	else
		echo "Existing $ZM_PATH_WEB/images is not a symlink. Aborting to prevent data loss"
		exit 10
	fi
fi

if [ -d "$ZM_PATH_WEB/events" ]; then
	if [ -L "$ZM_PATH_WEB/events" ]; then
		echo -n "Unlinking current symlink for the events folder... "
		unlink "$ZM_PATH_WEB/events"
		if [ "$?" = "0" ]; then
			echo "OK"
		else
			echo "Failed"
			exit 36
		fi
	else
		echo "Existing $ZM_PATH_WEB/events is not a symlink. Aborting to prevent data loss"
		exit 11
	fi
fi

# Create the symlink for the images folder
echo -n "Creating the symlink for the images folder... " 
ln -s -f "$ZM_PATH_CONTENT/images" "$ZM_PATH_WEB/images"
if [ "$?" = "0" ]; then
	echo "OK"
else
	echo "Failed"
	exit 15
fi
	
# Create the symlink for the events folder
echo -n "Creating the symlink for the events folder... " 
ln -s -f "$ZM_PATH_CONTENT/events" "$ZM_PATH_WEB/events"
if [ "$?" = "0" ]; then
	echo "OK"
else
	echo "Failed"
	exit 16
fi

# change ownership for the images folder. do it recursively unless -q is used
if [ -n "$QUICK" ]; then
	echo -n "Changing ownership of the images folder to ${ZM_WEB_USER} ${ZM_WEB_GROUP}... "
	chown ${ZM_WEB_USER}:${ZM_WEB_GROUP} "$ZM_PATH_CONTENT/images"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 20
	fi
else
	echo -n "Changing ownership of the images folder recursively to ${ZM_WEB_USER} ${ZM_WEB_GROUP}... "
	chown -R ${ZM_WEB_USER}:${ZM_WEB_GROUP} "$ZM_PATH_CONTENT/images"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 21
	fi
fi

# change ownership for the events folder. do it recursively unless -q is used
if [ -n "$QUICK" ]; then
	echo -n "Changing ownership of the events folder to ${ZM_WEB_USER} ${ZM_WEB_GROUP}... "
	chown ${ZM_WEB_USER}:${ZM_WEB_GROUP} "$ZM_PATH_CONTENT/events"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 25
	fi
else
	echo -n "Changing ownership of the events folder recursively to ${ZM_WEB_USER} ${ZM_WEB_GROUP}... "
	chown -R ${ZM_WEB_USER}:${ZM_WEB_GROUP} "$ZM_PATH_CONTENT/events"
	if [ "$?" = "0" ]; then
		echo "OK"
	else
		echo "Failed"
		exit 26
	fi
fi

# Change directory permissions for the images folder
echo -n "Changing permissions of the images folder to 775... "
chmod 775 "$ZM_PATH_CONTENT/images"
if [ "$?" = "0" ]; then
	echo "OK"
else
	echo "Failed"
	exit 30
fi


# Change directory permissions for the events folder
echo -n "Changing permissions of the events folder to 775... "
chmod 775 "$ZM_PATH_CONTENT/events"
if [ "$?" = "0" ]; then
	echo "OK"
else
	echo "Failed"
	exit 31
fi

echo ""
echo "All done"
