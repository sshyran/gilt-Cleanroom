#!/bin/bash

SCRIPT_NAME=`basename "$0"`
SCRIPT_DIR=`dirname "$PWD/$0"`

INHERIT_DIRNAME="inherit"
INHERIT_FILE_INCLUDE_PATH="../../../../BuildControl/config/inherit"

showHelp()
{
	echo "$SCRIPT_NAME"
	echo
	printf "\tSets up inheritance for Xcode configuration files.\n"
	echo
	printf "\tThis is useful for passing down configuration settings from a\n" 
	printf "\tcontaining Xcode project to contained Xcode projects. Normally,\n"
	printf "\tthe Xcode settings of a containing project are not inherited by\n"
	printf "\tcontained projects. This mechanism uses .xcconfig files to set\n"
	printf "\tup inheritance.\n"
	echo
	echo "Usage:"
	echo
	printf "\t$SCRIPT_NAME\n"
	echo
	echo "Optional arguments:"
	echo
	printf "\t--force\n"
	echo
	printf "\t\tThe --force (or -f) argument specifies that any local\n"
	printf "\t\tinheritence .xcconfig files will be overwritten with new ones.\n"
	echo
	printf "\t--inherit-dir <dir-path>\n"
	echo
	printf "\t\tThe --inherit-dir (or -i) argument specifies the path of a\n"
	printf "\t\tdirectory containing the .xcconfig files to inherit. This must\n"
	printf "\t\tbe a relative path that points to a directory within the file\n"
	printf "\t\tstructure of the containing project. If this argument is not\n"
	printf "\t\tsupplied, the following default will be used:\n"
	echo
	printf "\t\t\t${INHERIT_FILE_INCLUDE_PATH}\n"
	echo
	echo "Help"
	echo
	printf "\tThis documentation is displayed when supplying the --help (or\n"
	printf "\t-h or -?) argument.\n"
	echo
	printf "\tNote that when this script displays help documentation, all other\n"
	printf "\tcommand line arguments are ignored and no other actions are performed.\n"
	echo
}

printError()
{
	echo "error: $1"
	echo
	if [[ ! -z $2 ]]; then
		printf "  $2\n\n"
	fi
}

exitWithError()
{
	printError "$1" "$2"
	exit 1
}

exitWithErrorSuggestHelp()
{
	printError "$1" "$2"
	printf "  To display help, run:\n\n\t$0 --help\n"
	exit 1
}

#
# parse the command-line arguments
#
while [[ $1 ]]; do
	case $1 in
	--help|-h|-\?)
		SHOW_HELP=1
		;;
	
	--force|-f)
		FORCE_MODE=1
		;;
		
	--inherit-dir|-i)
		if [[ ! -z "$2" ]]; then
			INHERIT_FILE_INCLUDE_PATH="$2"
			shift
		else
			exitWithErrorSuggestHelp "The $1 argument requires a value"
		fi
		;;
		
	*)
		exitWithErrorSuggestHelp "Unrecognized argument: $1"
		;;
	esac
	shift
done

cd "$SCRIPT_DIR/../config"

if [[ $SHOW_HELP ]]; then
	showHelp
	exit
fi

mkdir -p inherit "$INHERIT_DIRNAME"

for CONFIG_FILENAME in *.xcconfig; do
	INHERIT_FILE="${INHERIT_DIRNAME}/${CONFIG_FILENAME}"
	INHERIT_INCLUDE="#include \"${INHERIT_FILE}\""
	FIRST_LINE=`head -1 "$CONFIG_FILENAME"`
	if [[ "$FIRST_LINE" != "$INHERIT_INCLUDE" ]]; then
		echo "Enabling Xcode config inheritance for: ${CONFIG_FILENAME}"
		BACKUP_FILENAME="${CONFIG_FILENAME}.bak"
		cp -f "$CONFIG_FILENAME" "$BACKUP_FILENAME"
		printf "${INHERIT_INCLUDE}\n\n" > "$CONFIG_FILENAME"
		cat "$BACKUP_FILENAME" >> "$CONFIG_FILENAME"
		rm -f "$BACKUP_FILENAME"
	else
		echo "Xcode config inheritance already enabled for: ${CONFIG_FILENAME}"
	fi
	
	if [[ $FORCE_MODE || ("$FIRST_LINE" != "$INHERIT_INCLUDE") ]]; then
		if [[ $FORCE_MODE ]]; then
			echo "Overwriting Xcode config inheritance file: ${INHERIT_FILE}"
		fi
		printf "// this file generated by ${SCRIPT_NAME}\n\n#include \"${INHERIT_FILE_INCLUDE_PATH}/${CONFIG_FILENAME}\"\n" > "$INHERIT_FILE"
	fi
done
