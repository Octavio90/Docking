#!/home/scidb/anaconda3/bin/python
import sys
import getopt

def save_file(file_name,text,dir='./'):
	o_file = open(dir+file_name.upper()+'.pdb','w')
	o_file.write(text)
	o_file.close()


def filter_receptor(pdb_file):
	o_lines  = ''
	receptor_name = pdb_file.split('/')[-1].split('.')[0]
	with open(pdb_file,'r') as i_file:
		i_lines = i_file.readlines()
		
	for line in i_lines:
		if line[0:6].strip() == 'ATOM':
			o_lines += line
	save_file('R_'+receptor_name,o_lines)

def filter_ligand(pdb_file,r_name,s_code):
	o_lines = ''
	receptor_name = pdb_file.split('/')[-1].split('.')[0] 
	with open(pdb_file,'r') as i_file:
		i_lines = i_file.readlines()
	for line in i_lines:
		a_type   = line[0:6]
		res_name = line[17:20]
		chain_id = line[21:22]
		if a_type.strip() == 'HETATM' and res_name.strip() == r_name and chain_id.strip() == s_code:
			o_lines += line
	save_file('L_'+receptor_name+'_'+r_name+'_'+s_code,o_lines)

def help():
	mess = '\n:: Input ::'
	mess+= '\nIf only PDB file is passed, split receptor from PDB'
	mess+= '\n\t-f --file:        PDB file'
	mess+= '\n\nOptional Parameters (for ligand splitting):' 
	mess+= '\n\t[-r --residue]:  Receptor\'s Name' 
	mess+= '\n\t[-c --chain]  :  Chain identifier'
	mess+= '\n\n:: Output ::'
	mess+= '\n\tR_<pdb>.pdb'
	mess+= '\n\tL_<pdb>_<residue>_<chain>.pdb\n'
	return mess

def main(argv):
	pdb_file = ''
	res_name = ''
	chain_id = ''
	try:
		opts, args = getopt.getopt(argv,'f:r:c:',['file=','residue=','chain='])
	except getopt.GetoptError:
		print(help())
		sys.exit(2)

	for opt, arg in opts:
		if opt in ('-h', '--'):
			print(help())
			sys.exit()
		if opt in ('-f', '--file'):
			pdb_file = arg
		if opt in ('-r', '--residue'):
			res_name = arg.upper()
		if opt in ('-c','--chain'):
			chain_id = arg.upper()
	
	if pdb_file != '' and res_name != '' and chain_id != '':
		filter_ligand(pdb_file,res_name,chain_id)
	elif pdb_file != '' and res_name == '' and chain_id == '':
		filter_receptor(pdb_file)
	else:
		print(help())
		sys.exit()

if __name__ == '__main__':
	if(len(sys.argv) == 1):
		print(help())
	else: 
		main(sys.argv[1:])

