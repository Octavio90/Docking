#!/bin/bash

py_dir="py_scripts"
sh_dir="sh_scripts"
pdb_dir="pdbs"
pdbqt_dir="pdbqts"
input="$1"
current=$2
log=$3
#if [[ -f $log ]]; then
#	rm $log
#fi
###########################
if [[ -z $log ]]; then 
	log="docking_batch.log"
fi

############################
if [[ -z $current ]]; then
	i=0
else
	i=$current
fi
###########################
while read line; do
	(( i++ ))
	## Set varibles
	dock_name=$(echo $line | cut -d' ' -f1)
	pdb=$(echo $dock_name | cut -d'_' -f1)
	res=$(echo $dock_name | cut -d'_' -f2)
	chain=$(echo $dock_name | cut -d'_' -f3)

	#echo "Empezando en la linea $i file: $dock_name log_file: $log"
	#exit

	## Docking
	scores=$(./docking.sh --pdb "$pdb_dir/$pdb.pdb" --residue $res --chain $chain --delete --size_box "20,20,20" | tail -n1)
	o_score=$(./docking.sh --r_pdbqt "$pdbqt_dir/R_$pdb.pdbqt" --l_pdbqt "$pdbqt_dir/L_$dock_name.pdbqt" --score_only | cut -d' ' -f2)
	echo "$i: $scores| $o_score" >> "$log"

	## Gen Box
	./$py_dir/get_visual_box.py "$pdbqt_dir/L_$dock_name.pdbqt" 20,20,20	 
	if [[ -f "box.pdb" ]]; then
		mv "box.pdb" "boxes/L_$dock_name.box"
	fi
done < $input
