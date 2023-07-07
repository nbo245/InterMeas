#used to setup anaconda environment:
#python setup_environment.py

import os
import time
import subprocess

start = time.time()
print("Setting up anaconda environment now...")

#Create Anaconda environment
conda_env_name = "InterMeas"
conda_packages = "python=3.8.5 psutil=5.8.0 tqdm=4.60.0 matplotlib=3.4.1 opencv=4.7.0 seaborn=0.11.1 pytorch=2.0.1 torchvision=0.15.2 torchaudio=2.0.2 pytorch-cuda=11.8 cudatoolkit=11.5.0 lxml=4.9.2 pyyaml=6.0 tensorboard=2.13.0 m2-base"

#Create Anaconda environment
create_env_command = f"conda create --name {conda_env_name} {conda_packages} -c pytorch -c nvidia -c conda-forge -c menpo -y"
subprocess.run(create_env_command, shell=True)

print("Environment setup, adding additional packages now...")

#Activate Anaconda environment
activate_env_command = f"conda activate {conda_env_name}"
subprocess.run(activate_env_command, shell=True)

print("Installing labelImg")

#Install labelImg
labelImg_install_command = f"git clone https://github.com/heartexlabs/labelImg"
subprocess.run(labelImg_install_command, shell=True)
labelImg_setup_command = f"pyrcc5 -o labelImg/libs/resources.py labelImg/resources.qrc"
subprocess.run(labelImg_setup_command,shell = True)

#Install yolov5
print("Installing yolov5")
yolo_install_command = f"git clone https://github.com/ultralytics/yolov5"
yolo_requirements_command = f"pip install -r yolov5/requirements.txt"
subprocess.run(yolo_install_command, shell = True)
subprocess.run(yolo_requirements_command, shell = True)

#locating python install path
print("Finding python path")
location_command = f"python path_locator.py"
subprocess.run(location_command, shell = True)

#consolidating locations for config file:



end = time.time()
total = end - start
print("Setup complete in " + "%.2f" % total + " seconds.")

# Deactivate Anaconda environment
deactivate_env_command = "conda deactivate"
subprocess.run(deactivate_env_command, shell=True)

