#!/bin/bash

docking_dir="."
script_dir="script"

###############################################################################
## Menu ##
##########

function help(){
	echo " Usage:"
	echo -e "   -h --help       : Help"
	echo -e "   -f --file       : List file (rows: RRRR_LLL_C)"
	echo -e "      --pdb_dir    : PDB directory"
	echo -e "      --pdbqt_dir  : PDBQT directory"
	echo -e "   -o --output     : Output file"
	echo -e "   -v --verbose    : Print steps"
	echo -e "\n"
}

verbose="False"
options=$(getopt -o :f:ohv --long file:,output:,pdb_dir:,help,verbose -- "$@")
set -- $options
while [[ $# -gt 0 ]]; do
	case $1 in
		-f|--file)
			file=$(echo $2 | tr -d \') 
			shift
			;;
		-o|--output)
			output=$(echo $2 | tr -d \') 
			shift
			;;
		-d|--pdb_dir)
			pdb_dir=$(echo $2 | tr -d \') 
			shift
			;;
		-v|--verbose)
			verbose="True"
			;;
		-h|--help)
			help 
			exit 0
			;;
		--) shift; break;;
		* ) echo "Error! "; exit 1 ;;
	esac
	shift
done


###############################################################################
## Main ##
##########

if [[ -z $file ]] || [[ -z $output ]] || [[ -z $pdb_dir ]];then
	help
	exit 0
fi

pdb_dir=$(echo $pdb_dir | awk '{c=substr($0,length($0));if(c=="/"){print substr($0,1,length($0)-1)} }')

c_rows=$(wc -l $file | cut -d' ' -f1)
index=0

echo "--------------------------------------" >> $output

while read line; do
	(( index = $index + 1 ))
	if [[ "$verbose" == "True" ]];then
		echo "  ($index/$c_rows): $line"
	fi
	pdb=$(echo $line | cut -d'_' -f1 | awk '{print $0".pdb"}')
	chain=$(echo $line | cut -d'_' -f3)
	residue=$(echo $line | cut -d'_' -f2)
	if [[ ! -f "$pdb_dir/$pdb" ]]; then 
		echo "Downloading $pdb"
		pdb_name=$(echo $pdb | cut -d'.' -f1)
		"./$script_dir/get_pdb.sh $pdb_name $pdb_dir"
	fi
	if [[ -f  ]]
	result=$(bash "$docking_dir/docking.sh" --pdb "$pdb_dir/$pdb" --residue $residue --chain $chain -s 15,15,15)

	if [[ "$verbose" == "True" ]];then
		echo "    $result"
	fi 
	echo $result >> $output
done < $file
