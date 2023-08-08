#used to setup anaconda environment:
#python setup_environment.py

import os
import time
import subprocess

#Create Anaconda environment
conda_env_name = "InterMeas"
conda_packages = "python=3.8.5 psutil=5.8.0 tqdm=4.64.0 matplotlib=3.4.1 opencv=4.7.0 seaborn=0.11.1 pytorch=2.0.1 torchvision=0.15.2 torchaudio=2.0.2 pytorch-cuda=11.8 cudatoolkit=11.5.0 lxml pyyaml=6.0 tensorboard=2.13.0 m2-base ultralytics"
current_location = os.getcwd()

#defs to make sure things get installed correctly on a spotty internet connection...
def run_command(command, retries=3):
    for i in range(retries):
        result = subprocess.run(command, shell=True, check=True)
        if result.returncode == 0:
            return True
        print(f"Command failed. Retry {i+1}/{retries}...")
    return False

def setup_environment():
    start = time.time()

    print("Setting up environment...")

    create_environment() #create InterMeas Env
    launch_environment() #launch it
    install_labelimg() #install labelimg for manual annotation checks
    install_yolov5() #install yolov5 for automatic annotations
#    install_yolo_reqs()
    locate_python_path() #add paths to a file

    run_command("conda deactivate")
    end = time.time()
    total = end - start
    print("Setup complete in " + "%.2f" % total + " seconds.")

def create_environment():
    print("Initilizing Environment, this might take a while...")
    run_command("conda install -n base conda-libmamba-solver -y") #install libmamba for faster environment solving
    run_command(f"conda create --name {conda_env_name} {conda_packages} -c pytorch -c nvidia -c conda-forge -c menpo -c anaconda -y --solver=libmamba")

def launch_environment():
    print("Launching InterMeas Env.")
    run_command("conda activate InterMeas")

def install_labelimg():
    print("Installing labelImg")
    run_command("git clone https://github.com/heartexlabs/labelImg")
    run_command("python -m pip install pyqt5-tools")
    run_command("pyrcc5 -o labelImg/libs/resources.py labelImg/resources.qrc")

def install_yolov5():
    print("Installing yolov5")
    run_command("git clone https://github.com/ultralytics/yolov5")
#    run_command("python -m pip install -r yolov5/requirements.txt")

def install_yolo_reqs():
    print("Intalling yolo_reqs")
    run_command("python -m pip install ultralytics")

def locate_python_path():
    print("Finding python path")
    run_command("python path_locator.py")

if __name__ == "__main__":
    setup_environment()