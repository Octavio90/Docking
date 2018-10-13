#!/bin/bash

scripts="./scripts"
configs="./pdbqts/configs"
ligand_pdbqt="./pdbqts/ligands"
docking_pose="./pdbqts/poses"
docking_output="./pdbqts/outputs"
receptor_pdbqt="./pdbqts/receptors"
vina_dir="./software/autodock_vina_1_1_2_linux_x86/bin"
mgl_dir="./software/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24"
pythonsh="./software/mgltools_x86_64Linux2_1.5.6/bin/pythonsh"
###############################################################################
## Functions ##
###############

function split(){
	local receptor=$1
	local residue=$2
	local chain=$3
	local prefix=$(echo $receptor | awk -F'/' '{n=split($NF,a,".");print a[1]}')

	local receptor_name="R_"$prefix".pdb"
	local ligand_name="L_"$prefix"_"$residue"_"$chain".pdb"
	delete $receptor_name $ligand_name

	## Filter Receptor and Ligand
	python "$scripts/filter_pdb.py" --file $receptor
	python "$scripts/filter_pdb.py" --file $receptor --residue $residue --chain $chain
	echo "$receptor_name,$ligand_name"
}


function keep_pdb_a(){ 
	local receptor=$1
	local new_receptor=$(echo $receptor | cut -d'.' -f1)

	## Keeping A
	bash "$scripts/keep_pdb_a.sh" $receptor > $new_receptor".tmp"
	delete $receptor
	mv $new_receptor".tmp" $receptor
}


function prepare(){
	local receptor=$(echo $1 | cut -d'.' -f1)
	local ligand=$(echo $2 | cut -d'.' -f1)

	## Changing into pdbqt format
	$pythonsh "$mgl_dir/prepare_receptor4.py" -r "$receptor.pdb" -A "hydrogens" >> /dev/null
	$pythonsh "$mgl_dir/prepare_ligand4.py"   -l "$ligand.pdb"   -A "hydrogens" >> /dev/null

	mv $ligand".pdbqt"   $ligand_pdbqt
	mv $receptor".pdbqt" $receptor_pdbqt
	delete $ligand".pdb" $receptor".pdb"
	echo "$receptor_pdbqt/$receptor.pdbqt,$ligand_pdbqt/$ligand.pdbqt" 
}

function make_config(){
	local ligand=$1
	local prefix=$(echo $1 | cut -d'_' -f2,3,4 | cut -d'.' -f1)
	delete $prefix"_config.txt"
	
	## Making config file
	bash "$scripts/make_config.sh" -f $ligand -s $size_box
	mv   $prefix"_config.txt" $configs
	echo $configs"/"$prefix"_config.txt" 
}


function docking(){
	local receptor=$1
	local ligand=$2
	local conf_file=$3
	local output=$(echo $ligand | awk -F'/' '{split($NF,a,".");print a[1]".out"}')
	
	if [[ "$score_only" == "True" ]]; then
		$vina_dir"/vina" --receptor $receptor --ligand $ligand --score_only > "$output"
		affinity=$(awk -F' ' '$1=="Affinity:"{print $2}' "$output")
		echo $affinity
	else
		pose=$(echo $output | cut -d'.' -f1)
		pose=$ligand_pdbqt"/"$pose"_out.pdbqt"

		$vina_dir"/vina" --receptor $receptor --ligand $ligand --score_only > "out.tmp"
		$vina_dir"/vina" --receptor $receptor --ligand $ligand --config $conf_file > "$output"
		
		affinity=$(awk -F' ' '$1=="Affinity:"{print $2}' "out.tmp")
		scores=$(grep -v "#" $output | awk -F' ' 'BEGIN{ORS=","}NF==4{if($1<10){print $2}}' | awk '{print substr($0,1,length-1)}')
		rm "out.tmp"
		mv $pose $docking_pose

		echo "$affinity|$scores"
	fi
	mv $output $docking_output
}

function delete(){
	args=( $@ )
	for file in ${args[*]}; do
		if [[ -f "$file" ]]; then
			rm "$file"
		fi
	done
}

###############################################################################
## Menu ##
##########

function help(){
	echo " Usage:"
	echo -e "   -h --help       : help"
	echo -e "   -p --pdb        : PDB file          "
	echo -e "   -r --residue    : Residue name      "
	echo -e "   -c --chain      : Chain identifier  "
	echo -e "   -s --size_box   : String of coordenates separated by ',' (default: \"15,15,15\")"
	echo -e "   -o --score_only : Perform docking with score_only parameter"
	echo -e "   -v --verbose    : Print steps"
	echo -e "\n"
}

size_box="15,15,15"
score_only="False"
options=$(getopt -o :p:r:c:s:hov --long pdb:,residue:,chain:,size_box:,help,score_only,verbose -- "$@")
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
			score_only="True"
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

if [[ -z $pdb ]] || [[ -z $residue ]] || [[ -z $chain ]]; then
	help
	exit 1
fi

###############################################################################
## Main ##
##########

 

if [[ ! -z $verbose ]]; then 
	echo -e "\nPerforming Docking on PDB: $pdb with Residue: $residue and Chain: $chain, score_only: $score_only"
	echo "  Splitting PDB into ligand and receptor files ..."
fi

c_receptor=$(wc -l $pdb | cut -d' ' -f1)
if [[ $c_receptor -eq 0 ]]; then
	if [[ ! -z $verbose ]]; then
		echo "  Error: Empty File, trying to download again ... "
	fi
	pdb_dir=$(echo $pdb | awk -F'/' '{for(i=1;i<NF;i++){printf("%s/",$i)}}')
	pdb_name=$(echo $pdb | awk -F'/' '{print $NF}' | cut -d'.' -f1)
	rm $pdb
	bash $scripts"/get_pdb.sh" --pdb $pdb_name --dir $pdb_dir
	c_receptor=$(wc -l $pdb | cut -d' ' -f1) 
	if [[ $c_receptor -eq 0 ]]; then
		echo "  Error: Second File Empty, stopping execution"
		exit 0
	fi
fi

fnames=$(split $pdb $residue $chain)
receptor=$(echo $fnames | cut -d',' -f1)
ligand=$(echo   $fnames | cut -d',' -f2)

if [[ ! -z $verbose ]]; then 
	echo "  Cleaning Receptor ..."
fi

keep_pdb_a $receptor


if [[ ! -z $verbose ]]; then 
	echo "  Preparing Ligand and Receptor for docking (changing into pdbqt) ..."
fi

fnames=$(prepare $receptor $ligand)
receptor=$(echo $fnames | cut -d',' -f1)
ligand=$(echo $fnames | cut -d',' -f2)

if [[ ! -z $verbose ]]; then 
	echo "  Creating config file ..."
fi

conf_file=$(make_config $ligand)


if [[ ! -z $verbose ]]; then 
	echo "  Performing Docking ..."
fi


result=$(docking $receptor $ligand $conf_file)
docking_id=$(echo $ligand | cut -d'_' -f2,3,4 | cut -d'.' -f1)
if [[ ! -z $verbose ]]; then 
	echo "Result: "$docking_id"|"$result
else
	echo $docking_id"|"$result 
fi

