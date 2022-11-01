# =============================================================================
# modified to crop out blue backmat
#also added parallelization to increase processing speed
#Threading on 12 cores reduced crop time of 100 images from 53.3 seconds to 9.3 seconds
# =============================================================================

import os
import time
import cv2 as cv2
import argparse
import glob
import numpy as np
#from joblib import Parallel, delayed
from threading import Thread


start = time.time()

parser = argparse.ArgumentParser(description='Will crop images from input folder and output them into a new folder')
# parser.add_argument('-input', metavar='path', type=str, help='Folder containing input images.', default='Input_Folder')
parser.add_argument('-input', type=str, help='Folder containing input images.', default='Input_Folder')

args = parser.parse_args()

inputFolder = args.input
folderLen = len(glob.glob(inputFolder + "/*.jpg"))

#check if output folder exists, if not, make
if not os.path.exists('Resized_Outputs'):
    os.makedirs('Resized_Outputs')

# define range of blue color in HSV
lower_blue = np.array([100,50,50])
upper_blue = np.array([130,255,255])

images = glob.glob(inputFolder + '\*.JPG')

def cropper(images):
    
    image = cv2.imread(images, cv2.IMREAD_COLOR)
    #convert to hsv
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    # Threshold the HSV image to get only blue colors
    mask = cv2.inRange (hsv, lower_blue, upper_blue)
    #identify contours for blue regions
    contours = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    contours = contours[0] if len(contours) == 2 else contours[1]
    # find the biggest countour (c) by the area; this should be the blue cutting mat
    c = max(contours, key = cv2.contourArea)
    #generate coordinates for region of interest
    x,y,w,h = cv2.boundingRect(c)
    
    #crop
    mat = image[y:y+h, x:x+w]
    
    basename = os.path.splitext(os.path.basename(images))[0]
    cv2.imwrite("Resized_Outputs/"f'{basename}_cropped.jpg', mat)
    #cv2.imwrite("Resized_Outputs/", crop_img)

#num_cores = multiprocessing.cpu_count()
     
for i in images:
    t = Thread(target=cropper, args=(i,))
    t.start()
        
end = time.time()
total = end - start
print("Total elapsed time: " + "%.2f" % total + " seconds to process " + "%.0f" %folderLen + " images.")