#!/usr/bin/env bash

#VARS FOR INIT DIRS
SRC_FOLDER="src/"
PNG_FOLDER="png/"
DOTSH_NAME="run.sh"

#ECHOES
echo_usage () {
	echo "USAGE: ./gen.sh <init|purge|gen|run> <directory>"
}
echo_dir_not_exist () {
	echo "ERROR: Direcoty does not exist."
}

# INITIALIZE A DIRECTORY
init_dir () {
	if ! [[ -d "$1" ]]; then
		mkdir -p "$1"
		echo "mkdir -p $1"
	else
		echo "Directory '$1' already exists.. continuing."
	fi
	init_child_dir "$1" "$SRC_FOLDER"
	init_child_dir "$1" "$PNG_FOLDER"
}
init_child_dir () {
	local DIR_PATH="$1/$2"
	if ! [[ -d "$DIR_PATH" ]]; then
		mkdir -p "$DIR_PATH"
		echo "mkdir -p $DIR_PATH"
	fi
}

#PURGE A DIRECTORY AND ITS CONTENTS
purge_dir () {
	if [[ -d "$1" ]]; then
		echo "CONFIRM: This will delete the directory and all of its content: $1 ?"
		echo -n "[Y]es or [N]o: "
		read YNO
		case $YNO in
			[yY] | [yY][eE][sS] )
				rm -r -f "$1"
				echo "rm -r -f $1"
				;;
			[nN] | [nN][oO] )
				echo "purge cancelled."
				;;
		esac
	else
		echo_dir_not_exist
		exit 1
	fi
}

#GENERATE THE RUN.SH FOR THE DIRECTORY
generate_run_sh () {
	local WORKING_DIR="$1"
	if ! [[ -d "$WORKING_DIR" ]]; then
		echo_dir_not_exist
		exit 1
	fi

	#TRIM LAST '/' IF GIVEN (E.G. AUTOCOMPLETE)
	if [[ "${WORKING_DIR: -1}" == "/" ]]; then
		WORKING_DIR="${WORKING_DIR::-1}"
	fi

	#PREPARE RUN.SH
	local RUN_FILEPATH="$WORKING_DIR/$DOTSH_NAME"
	rm --force "$RUN_FILEPATH"
	echo "#!/usr/bin/env bash" > "$RUN_FILEPATH"
	echo 'cd "$(echo "$(pwd)/$0" | rev | cut -d '/' -f 1 --complement | rev)"' >> "$RUN_FILEPATH"

	#FIND IUML-SOURCE FILES
	SRC_FILES=$(ls -l "$WORKING_DIR/$SRC_FOLDER" | awk '{if(NR>1)print $9}')

	#CREATE JAR-COMMANDS
	local JARCOM="java -jar ../plantuml.jar"
	while IFS= read -r FILE; do
		echo "$JARCOM $SRC_FOLDER$FILE &" >> "$RUN_FILEPATH"
	done <<< "$SRC_FILES"

	#WAIT FOR PROCESSES
	echo "wait" >> "$RUN_FILEPATH"

	#CREATE MV-COMMANDS
	echo "mv $SRC_FOLDER*.png $PNG_FOLDER" >> "$RUN_FILEPATH"

	#MAKE RUN.SH EXECUTEABLE
	chmod +x "$RUN_FILEPATH"
}

#RUN THE RUN.SH
exe_run_sh () {
	local WORKING_DIR="$1"
	if ! [[ -d "$WORKING_DIR" ]]; then
		echo_dir_not_exist
		exit 1
	fi

	#TRIM LAST '/' IF GIVEN (E.G. AUTOCOMPLETE)
	if [[ "${WORKING_DIR: -1}" == "/" ]]; then
		WORKING_DIR="${WORKING_DIR::-1}"
	fi

	#PREPARE RUN.SH
	local RUN_FILEPATH="$WORKING_DIR/$DOTSH_NAME"
	if [[ -f "$RUN_FILEPATH" ]]; then
		"./$RUN_FILEPATH"
	fi
}

# ------ MAIN --------
#CHECK ARGS TO SCRIPT
if [[ $# -lt 2 ]]; then
	echo "ERROR: You need to supply arguments to run gen.sh"
	echo_usage
	exit 1
fi

# SWITCH CASE FOR FUNCTION
case "$1" in
	init)
		init_dir "$2"
		;;
	purge)
		purge_dir "$2"
		;;
	gen)
		generate_run_sh "$2"
		;;
	run)
		exe_run_sh "$2"
		;;
	*)
		echo_usage
esac
