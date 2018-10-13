#!/usr/bin/env python
import numpy as np
import sys

def readfile(fileformat,filename):
    valid_formats = ['mol2','pdb','pdbqt']
    if fileformat not in valid_formats:
       print "File Format not valid.\
               Valid formnat are:\n\
               mol2, pdb, pdbqt."
       sys.exit(2)
    else:
       dat = open(filename,'r').readlines()
       coordinates = []
       if fileformat == 'mol2':
          flag = False
          for line in dat:
              line = line.split('\n')[0]
              if "<TRIPOS>ATOM" in line:
                  flag = True
                  continue
              if "<TRIPOS>BOND" in line:
                  flag = False
                  continue
              if flag and not ' H ' in line:
                 line = line.split()
                 coordinates.append(np.array([ float(i) for i in line[2:5] ]))
       if fileformat == 'pdb' or fileformat == 'pdbqt':
          for line in dat:
              line = line.split('\n')[0]
              if ("ATOM" in line or "HETATM" in line) and not 'H' in line.split()[-1]:
                  flag = True
                  x = float(line[30:38])
                  y = float(line[38:46])
                  z = float(line[46:54])
                  coordinates.append(np.array([ x,y,z ]))
       return coordinates

def get_COM(mymol):
    return np.average(mymol,axis=0)

assert( len(sys.argv)>1)
main_name = sys.argv[0]
realname = sys.argv[1]
box = sys.argv[2]
size = np.array([ float(i) for i in box.split(',')])*0.5

refname = realname.split('.')[0]
refformat = realname.split('.')[1]
ref = readfile('%s'%refformat,'%s.%s'%(refname,refformat))
com = get_COM(ref)
out_file = open('box.pdb','w')
line = 'REMARK Box generated using'
out_file.write('%s\n'%line)
line = 'REMARK %s %s %s'%(main_name,realname,box)
out_file.write('%s\n'%line)

sequence = [[1.,1.,1.],[1.,-1.,1.],[1.,1.,-1.],[1.,-1.,-1.],\
            [-1,1.,1.],[-1.,-1.,1.],[-1.,1.,-1.],[-1.,-1.,-1.]]
count = 1
for cor in sequence:
    corner = com+(size*np.array(cor))
    line = "HETATM    %s  CAJ DRG X   1    %8.3f%8.3f%8.3f  1.00 00.00           C"%(count,corner[0],corner[1],corner[2])
    count += 1
    out_file.write('%s\n'%line)

line = "HETATM    %s  CAJ DRG X   1    %8.3f%8.3f%8.3f  1.00 00.00           N"%(count,com[0],com[1],com[2])
out_file.write('%s\n'%line)
line = "CONECT 1 2 5\n"\
       "CONECT 1 4 2\n"\
       "CONECT 2 3 6\n"\
       "CONECT 3 7 4\n"\
       "CONECT 4 7 8\n"\
       "CONECT 5 8 6\n"\
       "CONECT 4 6 2\n"\
       "CONECT 8 2 6\n"\
       "CONECT 1 7 3\n"\
       "CONECT 3 5 7\n"\
       "CONECT 7 1 5\n"\
       "CONECT 7 6 8\n"\
       "END"
out_file.write('%s'%line)
out_file.close()
