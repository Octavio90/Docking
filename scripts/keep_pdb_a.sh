#!/bin/bash


function keep_pdb_a (){ 
	awk '{stt=substr($0,17,1)}(stt!=" "&&f==0){a[0]=stt;f=1}(stt==a[0]&&f){print substr($0,1,16)" "substr($0,18);next}(stt==" "){print $0}' "$1";
}



pdb=$1
keep_pdb_a $pdb 





