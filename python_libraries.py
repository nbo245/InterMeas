#libraries
import sys
import os
import time
import cv2 as cv2
import argparse
import glob
import numpy as np
from threading import Thread
import contextlib
import glob
import inspect
import logging
import math
import os
import platform
import random
import re
import shutil
import signal
import threading
import time
import urllib
from datetime import datetime
from itertools import repeat
from multiprocessing.pool import ThreadPool
from pathlib import Path
from subprocess import check_output
from typing import Optional
from zipfile import ZipFile

import pandas as pd
import torch
import torchvision
import yaml


# Open the configs file and read the 6th line
with open('configs_mod.txt', 'r') as f:
    check = f.readlines()

#append path to sys    
sys.path.append(check[5].strip()[9:]) #append yolo dir path from 6th line of configs file
root_path = os.getcwd()
#print("root=",root_path)

os.chdir(check[5].strip()[9:]) #go to yolo dir
os.chdir("..")

#current_path=os.getcwd()
#print("yolo_path=",current_path)

from yolov5 import * #import detection script and everything else
os.chdir(root_path) #go back to working directory
#print("returned to: ",os.getcwd())