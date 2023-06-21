#used to setup anaconda environment:
#python setup_environment.py

import os
import subprocess

print("Setting up anaconda environment now...")

# Create Anaconda environment
conda_env_name = "InterMeas"
conda_packages = "python=3.8.5 psutil=5.8.0 tqdm=4.60.0 matplotlib=3.4.1 seaborn=0.11.1 pytorch torchvision torchaudio pytorch-cuda=11.8 cudatoolkit lxml"
pip_packages = "opencv-python-headless PyYAML tensorboard lxml"

# Create Anaconda environment
create_env_command = f"conda create --name {conda_env_name} {conda_packages} -c pytorch -c nvidia -y"
subprocess.run(create_env_command, shell=True)

print("Environment setup, adding additional packages now...")

# Activate Anaconda environment
activate_env_command = f"conda activate {conda_env_name}"
subprocess.run(activate_env_command, shell=True)

# Install additional pip packages
pip_install_command = f"pip3 install {pip_packages}"
subprocess.run(pip_install_command, shell=True)

print("Setup complete.")

# Deactivate Anaconda environment
deactivate_env_command = "conda deactivate"
subprocess.run(deactivate_env_command, shell=True)

