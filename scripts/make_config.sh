#!/bin/bash

script_dir="scripts"

function help(){
	echo "Usage:"
	echo -e "\t -h  : help"
	echo -e "\t -f  : Receptor PDB file (necessary)"
	echo -e "\t -s  : String of coordenates separated by ',' (default: \"15,15,15\")"
}

function get_coord(){
	local coord=$("./$script_dir/get_center.py" --file "$1")
	echo "$coord"
}

function write_config(){
	local x=$(echo "$2" | cut -d',' -f1)
	local y=$(echo "$2" | cut -d',' -f2)
	local z=$(echo "$2" | cut -d',' -f3) 
	local b_x=$(echo "$3" | cut -d',' -f1)
	local b_y=$(echo "$3" | cut -d',' -f2)
	local b_z=$(echo "$3" | cut -d',' -f3)
	local r_name=$(echo "$1" | cut -d'_' -f2,3,4 | cut -d'.' -f1)
	local file_name=$(echo "$r_name""_config.txt")

	if [[ -f "$file_name" ]]; then
		rm "$file_name"
	fi
	echo -e "\n" >> "$file_name"
	echo -e "center_x = $x\ncenter_y = $y\ncenter_z = $z\n" >> "$file_name"
	echo -e "size_x = $b_x\nsize_y = $b_y\nsize_z = $b_z\n" >> "$file_name"
}


while getopts ":f:s:h" opt; do
	case ${opt} in
		h)
			help
			exit 0
			;;
		f)
			file_name=$OPTARG
			;;
		s) 
			size_box=$OPTARG
			;;
		\?)
			echo "Invalid Option: -$OPTARG"
			help
			exit 1
			;;
		:)
			echo "Option -$OPTARG rquires an argument"
			help
			exit 1
			;;
	esac
done

## Removing options that have been handdled from "$@"
shift $((OPTIND -1))


## Main Program

if [[ -z $file_name ]]; then
	help
	exit 0
fi

if [[ -z $size_box ]]; then
	size_box="15,15,15"
fi

coord=$(get_coord "$file_name")
write_config $file_name $coord $size_box
