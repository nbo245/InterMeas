#used to setup anaconda environment:
#python setup_environment.py

import os
import subprocess

print("Setting up anaconda environment now...")

#Create Anaconda environment
conda_env_name = "InterMeas"
conda_packages = "python=3.8.5 psutil=5.8.0 tqdm=4.60.0 matplotlib=3.4.1 seaborn=0.11.1 pytorch=2.0.1 torchvision=0.15.2 torchaudio=2.0.2 pytorch-cuda=11.8 cudatoolkit=11.5.0 lxml=4.9.2"
pip_packages = "opencv-python-headless PyYAML tensorboard"

#Create Anaconda environment
create_env_command = f"conda create --name {conda_env_name} {conda_packages} -c pytorch -c nvidia -y"
subprocess.run(create_env_command, shell=True)

print("Environment setup, adding additional packages now...")

#Activate Anaconda environment
activate_env_command = f"conda activate {conda_env_name}"
subprocess.run(activate_env_command, shell=True)

#Install additional pip packages
pip_install_command = f"pip install {pip_packages}"
subprocess.run(pip_install_command, shell=True)

print("Installing labelImg")

#Install labelImg
labelImg_install_command = f"git clone https://github.com/heartexlabs/labelImg"
subprocess.run(labelImg_install_command, shell=True)
labelImg_setup_command = f"pyrcc5 -o labelImg/libs/resources.py labelImg/resources.qrc"
subprocess.run(labelImg_setup_command,shell = True)

print("Setup complete.")

# Deactivate Anaconda environment
deactivate_env_command = "conda deactivate"
subprocess.run(deactivate_env_command, shell=True)

