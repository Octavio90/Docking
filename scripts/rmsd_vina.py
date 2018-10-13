#!/home/scidb/anaconda3/bin/python
import numpy as np
import sys

# Programa que calcula el error entre la pose correcta 
# de ligando y la pose obtenida mediante el docking


def readfile(fileformat,filename,pose_check=None,is_target=True):
    valid_formats = ['mol2','pdb','pdbqt']
    if fileformat not in valid_formats:
       print("File Format not valid.\
               Valid formnat are:\n\
               mol2, pdb.")
       sys.exit(2)
    else:
       dat = open(filename,'r').readlines()
       #coordinates = []
       #names = []
       dic_names = {}
       if fileformat == 'mol2':
          # awk '/ATOM/{f=1;next}/BOND/{f=0}(f&&!($6=="H"))' ligs/lig_1.mol2
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
                 #coordinates.append(np.array([ float(i) for i in line[2:5] ]))
                 #names.append([line[1],line[5]])
                 dic_names[line[1]] = np.array([float(i) for i in line[2:5]])
       if fileformat == 'pdbqt':
          #awk '/MODEL 1/{f=1;next}/ENDMDL/{f=0}(f&&!(/REMARK/||/TORSDOF/)&&!(index($NF,"H")))' oe8.pdbqt
          flag = False
          if is_target == True:
            for line in dat:
              line = line.split('\n')[0]
              if not 'H' in line.split()[-1] and not ('REMARK' or 'TORSDOF') in line:
                if 'ATOM' in line or 'HETATM' in line:
                  #print "{}".format(line)
                  #print "-> {}: {} {} {}".format(line.split()[2],line[30:38],line[38:46],line[46:54])
                  dic_names[line.split()[2]] = np.array([float(line[30:38]),float(line[38:46]),float(line[46:54])])
          else:
            for line in dat:
                line = line.split('\n')[0]
                if not pose_check == None:
                   model_to_check = "MODEL %s"%pose_check
                else:
                   model_to_check = "MODEL 1"
                if model_to_check in line:
                   flag = True
                   continue
                if "ENDMDL" in line:
                   flag = False
                   continue
                if flag and not 'H' in line.split()[-1] and not ('REMARK' or 'TORSDOF') in line:
                   if 'ATOM' in line or 'HETATM' in line:
                      #coordinates.append(np.array([ float(line[30:38]),float(line[38:46]),float(line[46:54])]))
                      #line = line.split()
                      #names.append([line[2],line[-1]])
                      dic_names[line.split()[2]] = np.array([float(line[30:38]),float(line[38:46]),float(line[46:54])])
       return dic_names


target = '%s'%sys.argv[1]
pose = '%s'%sys.argv[2]
pose_no = None
if len(sys.argv)>3:
   pose_no = '%s'%sys.argv[3]

target_f = target.split('.')[-1]
pose_f = pose.split('.')[-1]

r = readfile(target_f,target)
d = readfile(pose_f,pose,pose_no,False)

total = 0
n_atoms = len(r.keys())
if not n_atoms == len(d.keys()):
   print("Something is wrong!!! number of atoms does not concide.")
   sys.exit(2)
for at in r.keys():
    diff = d[at]-r[at]
    total += np.sum(diff*diff)
if n_atoms == 0:
  print("Division by 0: %s"%target)
else:
  print("%0.3f"%np.sqrt(total/float(n_atoms)))
