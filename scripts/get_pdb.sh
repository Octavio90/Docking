#!/bin/bash

function help(){
	echo "Usage:"
	echo -e "\t-h --help       : help"
	echo -e "\t-p --pdb        : PDB name              "
	echo -e "\t-d --dir        : Output Dir(default .) "
}


function download(){
	pdb=$(echo $1 | awk -F'/' '{n=split($NF,a,".");printf("%s",a[1])}')
	dir=$(echo $2 | awk '{c=substr($0,length($0)); if(c != "/"){print $0"/"} else {print $0}}' )
	query=$(echo "http://www.rcsb.org/pdb/files/$pdb.pdb -O $dir$pdb.pdb")
	wget -q $query
}

options=$(getopt -o :p:d --long pdb:,dir: -- "$@")
set -- $options
while [[ $# -gt 0 ]]; do
	case $1 in
		-p|--pdb)
			pdb=$(echo $2 | tr -d \')
			shift
			;;
		-d|--dir)
			dir=$(echo $2 | tr -d \')
			shift
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


if [[ $pdb == "" ]]; then
	help
	exit 0
fi

download $pdb $dir
