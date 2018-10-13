#!/bin/bash

############################################################################################
## Variables ##
###############

op="both"
r_pdbqt=""
l_pdbqt=""
pdbqt_dir="pdbqts"
score_only="false"
py_dir="py_scripts"
sh_dir="sh_scripts"
out_dir="output_docking"
conf_dir="config_docking"
lig_dock_dir="ligand_docking"
mgltools_dir="/home/octavio/docking/software/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24"
vina_dir="/home/octavio/docking/software/Vina/bin"
############################################################################################
## Functions ##
###############

function help(){
	echo "Usage:"
	echo -e "\t-h --help       : help"
	echo -e "\t-p --pdb        : PDB file          "
	echo -e "\t-r --residue    : Residue name      "
	echo -e "\t-c --chain      : Chain identifier  "
	echo -e "\t-s --size_box   : String of coordenates separated by ',' (default: \"15,15,15\")"
	echo -e "\t-d --delete     : Delete only pdb files (keep pdbqt files)"
	echo -e "\t-o --score_only : Perform docking with score_only parameter"
	echo -e "\t   --r_pdbqt    : Receptor in pdbqt format (to avoid pre-computing)"
	echo -e "\t   --l_pdbqt    : Ligand in pdbqt format (to avoid pre-computing)"
}

function filter(){
	local rec_name=$(echo "$1" | awk -F'/' '{print $NF}' | cut -d'.' -f1 | awk '{print toupper($0)}')
	local receptor="R_$rec_name.pdb"
	local ligand="L_$rec_name""_$2""_$3.pdb"
	
	if [[ -f $receptor ]]; then
		rm $receptor
	fi

	if [[ -f $ligand ]]; then
		rm $ligand
	fi

	if [[ "$4" == "ligand" ]]; then
		"./$py_dir/filter_pdb.py" -f $1 -r $2 -c $3
	elif [[ "$4" == "receptor" ]]; then
		"./$py_dir/filter_pdb.py" -f $1
	else
		"./$py_dir/filter_pdb.py" -f $1
		"./$py_dir/filter_pdb.py" -f $1 -r $2 -c $3
	fi

	echo "$receptor,$ligand"
}

function prepare_pdbqt(){

	if [[ "$3" == "ligand" ]]; then
		pythonsh "$mgltools_dir/prepare_ligand4.py"   -l "$2"  -A "hydrogens" >> /dev/null
	elif [[ "$3" == "receptor" ]]; then
		pythonsh "$mgltools_dir/prepare_receptor4.py" -r "$1"  -A "hydrogens" >> /dev/null
	else
		pythonsh "$mgltools_dir/prepare_receptor4.py" -r "$1"  -A "hydrogens" >> /dev/null
		pythonsh "$mgltools_dir/prepare_ligand4.py"   -l "$2"  -A "hydrogens" >> /dev/null
	fi
}

function make_config(){
	if [[ ! -f $1 ]]; then
		echo "Missing file for config file"
		exit 1
	fi
	local conf_file=$(echo "$1" | awk -F'/' '{print $NF}' | cut -d'.' -f1 | cut -d'_' -f2- | awk '{printf($0"_config.txt")}') 
	if [[ -f "$conf_file" ]]; then
		rm $conf_file
	fi
	
	"./$sh_dir/make_config.sh" -f "$1" -s "$2" 

	echo "$conf_file"
}

function delete(){
	args=( $@ )
	for file in ${args[*]}; do
		if [[ -f "$file" ]]; then
			#echo "Cleaning $file"
			rm "$file"
		fi
	done
}

function docking(){
	local name=$(echo "$2" | cut -d'.' -f1 | awk -F'_' '{print $2"_"$3"_"$4}')
	if [[ "$4" == "true" ]]; then
		lig=$(echo "$2" | awk -F'/' '{print $NF}' | cut -d'.' -f1)
		"$vina_dir/vina" --receptor "$1" --ligand "$2" --score_only > "$lig.out"
		affinity=$(grep "Affinity" "$lig.out" | cut -d' ' -f2)
		echo "$name $affinity"
		if [[ -f "$lig.out" ]]; then
			rm "$lig.out"
		fi
	else
		#echo "$1 ,$2, $3, $4"
		lig=$(echo "$2" | awk -F'/' '{print $NF}' | cut -d'.' -f1)
		"$vina_dir/vina" --receptor "$1" --ligand "$2" --config "$3" --cpu 10 --out "./$lig""_out.pdbqt" > "$lig.out"
		scores=$(awk -F' ' 'BEGIN{ORS=" "} NF==4 && $1~/^[0-9]+$/{print $2}' "$lig.out")
		#echo "--> $scores, $2, ./$lig""_out.pdbqt"
		rmsd=$("./$py_dir/rmsd_vina.py" --target "$2" --pose "$lig""_out.pdbqt")
		echo "$name $rmsd $scores"
	fi
}

############################################################################################
## Parameters ##
################


options=$(getopt -o :p:r:c:s:hd --long pdb:,residue:,chain:,size_box:,help,delete,score_only,r_pdbqt:,l_pdbqt: -- "$@")
set -- $options
while [[ $# -gt 0 ]]; do
	case $1 in
		-p|--pdb)
			pdb=$(echo $2 | tr -d \') 
			shift
			;;
		-r|--residue)
			residue=$(echo $2 | tr -d \') 
			shift
			;;
		-c|--chain)
			chain=$(echo $2 | tr -d \') 
			shift
			;;
		-s|--size_box)
			size_box=$(echo $2 | tr -d \') 
			shift
			;;
		-o|--score_only)
			score_only="true"
			;;
		--r_pdbqt)
			r_pdbqt=$(echo $2 | tr -d \')
			shift
			;;
		--l_pdbqt)
			l_pdbqt=$(echo $2 | tr -d \')
			shift
			;;
		-d|--delete)
			delete="true"
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

############################################################################################
## Main Program ##
##################

if [[ "$r_pdbqt" != "" ]] && [[ "$l_pdbqt" != "" ]]; then
	op="none"
elif [[ "$l_pdbqt" != "" ]]; then
	op="receptor"
elif [[ "$r_pdbqt" != "" ]]; then
	op="ligand"
else
	op="both"
fi

if [[ "$r_pdbqt" == "" ]] || [[ "$l_pdbqt" == "" ]]; then
	if [[ -z $pdb ]] || [[ -z $residue ]] || [[ -z $chain ]]; then
		help
		exit 0
	fi
fi

if [[ -z $size_box ]]; then
	size_box="15,15,15"
fi

delete "output"

## Filter de PDB into ligando and receptor files

if [[ "$op" != "none" ]]; then
	output=$(filter $pdb $residue $chain $op)
	if [[ "$op" == "receptor" ]]; then
		receptor=$(echo "$output" | cut -d',' -f1)
		"./$sh_dir/keep_pdb_a.sh" $receptor > "A-$receptor"
		if [[ -f "A-$receptor" ]]; then
			rm "$receptor"
			mv "A-$receptor" "$receptor"
		fi
		ligand="none"
	elif [[ "$op" == "ligand" ]]; then
		ligand=$(echo "$output" | cut -d',' -f2)
		receptor="none"
	else
		receptor=$(echo "$output" | cut -d',' -f1)
		"./$sh_dir/keep_pdb_a.sh" $receptor > "A-$receptor"
                if [[ -f "A-$receptor" ]]; then
                        rm "$receptor"
                        mv "A-$receptor" "$receptor"
                fi
		ligand=$(echo "$output" | cut -d',' -f2)
	fi
fi

## Using MGTools for preparing pdbqt files
if [[ "$op" != "none" ]]; then
	prepare_pdbqt $receptor $ligand $op

	if [[ "$delete" == "true" ]]; then
		delete $receptor $ligand
	fi


	if [[ "$op" == "receptor" ]]; then
		receptor=$(echo "$receptor""qt")
		ligand="$l_pdbqt"	
	elif [[ "$op" == "ligand" ]]; then
		receptor="$r_pdbqt"
		ligand=$(echo "$ligand""qt")
	else
		receptor=$(echo "$receptor""qt")
		ligand=$(echo "$ligand""qt")
	fi
else
	receptor="$r_pdbqt"
	ligand="$l_pdbqt"	
fi


 
## Make Config File for docking
conf_file="config.txt"

if [[ "$score_only" == "false" ]]; then
	conf_file=$(make_config $ligand $size_box)
fi


## Perform Docking
docking $receptor $ligand $conf_file $score_only

if [[ "$score_only" == "false" ]]; then
	if [[ -f "$(echo $receptor | awk -F'/' '{print $NF}')" ]]; then
		rep=$(echo $receptor | awk -F'/' '{print $NF}')
		if [[ -f "./$pdbqt_dir/$rep" ]]; then
			rm "./$pdbqt_dir/$rep"
			mv "$rep" "./$pdbqt_dir/"
		else
			mv "$rep" "./$pdbqt_dir/"	
		fi
	fi

	if [[ -f "$(echo $ligand | awk -F'/' '{print $NF}')" ]]; then
		lig=$(echo $ligand | awk -F'/' '{print $NF}')
		if [[ -f "./$pdbqt_dir/$lig" ]]; then
			rm "./$pdbqt_dir/$lig"
			mv "$lig" "./$pdbqt_dir/"
		else
			mv "$lig" "./$pdbqt_dir/"	
		fi
	fi
fi

# Cleaning
ligand=$(echo "$ligand" | cut -d'.' -f1)

if [[ -f "$(echo $ligand | awk -F'/' '{print $NF}')""_out.pdbqt" ]]; then
	lig="$(echo $ligand | awk -F'/' '{print $NF}')""_out.pdbqt"
	if [[ -f "./$lig_dock_dir/$lig" ]]; then
		rm "./$lig_dock_dir/$lig"
		mv  "$lig"  "./$lig_dock_dir/"
	else
		mv  "$lig"  "./$lig_dock_dir/"
	fi
fi

out=$(echo $lig | awk -F'\' '{split($NR,a,"_");print a[2]"_"a[3]"_"a[4]}' | cut -d'.' -f1)

#echo "----> L_$out"
#exit 0
if [[ -f "L_$out.out" ]]; then
	#out=$(echo $lig | awk -F'\' '{split($NR,a,"_");print a[2]"_"a[3]"_"a[4]}' | cut -d'.' -f1)
	if [[ -f "./$out_dir/$out""_results.txt" ]]; then
		rm "./$out_dir/$out""_results.txt"
		mv "L_$out.out" "./$out_dir/$out""_results.txt"
	else
		mv "L_$out.out" "./$out_dir/$out""_results.txt"
	fi

fi

if [[ -f "$conf_file" ]]; then
	if [[ -f "./$conf_dir/$conf_file" ]]; then
		rm "./$conf_dir/$conf_file"
		mv "$conf_file" "./$conf_dir/"
	else
		mv "$conf_file" "./$conf_dir/" 
	fi
fi

exit 0
