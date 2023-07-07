#small script to find filepath for python installed in this environment

import subprocess
import platform

environment = "InterMeas"

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
    with open("python_location.txt", "w") as file:
        file.write(found_line)
