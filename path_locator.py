#small script to find filepath for python installed in this environment

import os
import subprocess
import platform

environment = "InterMeas"

#find python.exe
#https://docs.anaconda.com/free/anaconda/configurations/python-path/
#determine operating system and write path as needed
if platform.system() == "Windows":
    command = f"conda activate {environment} && where python"
else:
    command = f"source activate {environment} && which python"

output = subprocess.check_output(command, shell=True, text=True).strip()

#Split the output into separate lines
lines = output.splitlines()

#Find the line that contains "thisone" and print it
found_line = next((line for line in lines if "InterMeas" in line), None)
if found_line:
    with open("path_info.txt", "w") as file:
        file.write(found_line)
        file.write('\n')
        
#add in additional paths
subprocess.run(["python", "-c", "import os; print(os.getcwd() + '\\\\yolov5\\\\')"], shell=True, stdout=open("path_info.txt", "a"), text=True) #path for yolov5 dir
subprocess.run(["python", "-c", "import os; print(os.getcwd() + '\\\\labelImg\\\\')"], shell=True, stdout=open("path_info.txt", "a"), text=True) #path for labelImg dir
subprocess.run(["python", "-c", "import os; print(os.getcwd() + '\\\\best_nodes.torchscript')"], shell=True, stdout=open("path_info.txt", "a"), text=True) #path for weights


