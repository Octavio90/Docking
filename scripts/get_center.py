#!/home/scidb/anaconda3/bin/python
import sys
import getopt
import numpy as np

def help():
	mess = "Usage:"
	mess+= '\nInput\n'
	mess+= '\n\t-f --file:  PDB or PDBQT file'
	mess+= '\nOutput\n'
	mess+= '\n\t geometric center coordinates\n'
	return mess

def get_center(file):
	coords = []	
	with open(file,'r') as file:
		i_lines = file.readlines()

	for line in i_lines:
		if (line[0:6].strip() == 'ATOM' or line[0:6].strip() == 'HETATM') and line[76:78].strip() != 'H':
			x = float(line[30:38].strip()) 
			y = float(line[38:46].strip())
			z = float(line[46:54].strip())
			coords.append(np.array([ x,y,z ]))
	return np.average(coords,axis=0)

def main(argv):
	file = ''
	try:
		opts,agrs = getopt.getopt(argv,'f:',['file='])

		for opt,agr in opts:
			if opt in ('-f','--file'):
				file = agr
			elif opt in ('-h','--'):
				print(help)
				sys.exit()
		coords = get_center(file)
		print('{:0.3f},{:0.3f},{:0.3f}'.format(coords[0],coords[1],coords[2]))
	except getopt.GetoptError:
		print(help())
		sys.exit(2)



if __name__ == '__main__':
	if(len(sys.argv) == 1):
		print(help())
		sys.exit()
	else:
		main(sys.argv[1:])		
