# InterMeas
An R Shiny dashboard wrapping a few python scripts and object detection algorithms into an easy to use internode measurment workflow.  

## Summary
This Shiny app uses the [YOLOv5](https://github.com/ultralytics/yolov5) object detection algorithm to identify maize nodal structures on top of a standardized background along stalk of maize.  Maize nodal detections are verified and manually adjusted as needed using [LabelImg](https://github.com/heartexlabs/labelImg).  These annotations are finally compiled and converted into internodal measurements saved in a single output excel sheet.

## Installation
1) Download and install [R and Rstudio](https://posit.co/download/rstudio-desktop/)
2) Download and install [Anaconda](https://www.anaconda.com/download).
   - *Optional:* If you have access to a CUDA capable GPU, install the appropriate CUDA [drivers](https://developer.nvidia.com/cuda-11-8-0-download-archive)
   - Annotation speeds significantly improve when using even a lower end CUDA-capable GPU:

| Hardware      | Type          | Time (~sec/image) |
| :------------ | :-----------: | ----------------: |
| Intel i7-11370H @ 3.3GHz  | CPU  | 2.5 |
| Intel Xeon E-2176G @ 3.7GHz  | CPU  | 2.2 |
| NVIDIA Quadro P620  | GPU  | 0.4 |
| NVIDIA RTX 3060 Laptop GPU | GPU  | 0.075 |
3) Open anaconda terminal and navigate into a place you can easily find in the future such as your Desktop.
```bash
cd Desktop/ #navigate to Desktop from your default conda home directory
```
4) Clone this repo via git.
```bash
git clone https://github.com/nbo245/InterMeas
# conda install -c anaconda git #If you need to download git
```
5) Run setup_environment.py script to create anaconda environment used by the main script.
```bash
cd InterMeas/
python setup_environment.py #this might take a few minutes depending on how many dependencies have to be installed
```
6) The yolov5, labelImg, and filepaths should automatically download and populate info into a file called path_info.txt.  Please don't delete or modify this file for now, it contains the filepaths for various dependencies needed by the main scripts...
7) Open the app.R script in Rstudio and hit the **Run App** button to run through the guided workflow. (Note the tip at the bottom of the page for easier setup later)

## Interactive usage via R:
Open R and run the run_autogenerator.R script.  Follow on-screen prompts to run through workflow.

## Shiny Usage (use the example_images directory supplied in this repo):
1) Select directory containing full-sized images ready for analysis by using the **Original Images** button to select appropriate target directory.
   - Once target directory is selected, click **Select**.
   - Click **Run Cropping Script** button.
     - Images will be cropped into a new directory called *Resized_Outputs/*
2) Annotate the cropped images by clicking the **Cropped Image Location** button; this should typically be the **Resized_Output/** directory modified in the previous step.
   - If GPU acceleration is available, select **GPU** otherwise, select **CPU**
      - *Note:* CPU will annotate images significantly slower, but can be used if a CUDA capable GPU is not available.
   - Click on the **Run Annotation Script** button.
3) Verify that the image annotations were correct by using [LabelImg](https://github.com/heartexlabs/labelImg) to inspect annotations.
   - Use **Cropped Image Location** button to select target directory containing cropped images w/ output labels contained in exp/labels subdirectory.  This should again typically be the **Resized_Output/** directory modified in the previous step.
   -  *Note: * Do not select the exp or labels directory, select the main directory containing these subdirectories and the cropped images.
   -  Click **Verify Labels** button.
   -  Use LabelImg to verify correct label annotation placement.
   -  Once all images are verified, exit the LabelImg popup and continue the InterMeas workflow.
4) To generate a details file, select location of verified images.
   - Click **Cropped Image Location** button to select target directory; this should typically be the **Resized_Output/** directory modified in the previous step.
   - Set ID Start to the nth character in image filename to use as the first character in stalk identifier.
   - Set ID End to the nth character in the image filename to use as the last character in the stalk identifier.
   - Click the **Make Details File** button.
5) Run the final Internode Measurement script.
   - Click **Cropped Image Location** button to select target directory; this should typically be the **Resized_Output/** directory modified in the previous step.
   - Use the **Browse..** button to select the details_file.csv file generated in the previous step.
   - Click the **Run Analysis** button**
  
## Output Interpretation

The output of **Run Analysis** button is a file called data_output.xlsx.  The file has the following columns, with one row per stalk analyzed:
- annotation_id: The basename of an analyzed file
- x_pos: The horizontal pixel position of an annotated node
- y_pos: The vertical pixel position of an annotated node
- group: The grouping identifier specified by the start and end character ids in **Step 4** above
- height: The pixel height of a cropped image
- width: The pixel width of a cropped image
- Stalk_number: A numerical identifier for the nth image/stalk analyzed in the current run
- converter: The width of an individual image in pixels divided by the known width of the imaging background (defaults to a 36 inch width; can be changed by modifying line 114 in the helper_functions.R script)
- Total_Internodes: The number of unique internodes idenified in a stalk
- Sum_Internodes: The sum length of all imaged internodes in centimeters.
- z_score: The z-score furthest from zero for an internode measured along a particular stalk.  Useful for identifying erronously annotated images.
- outliers: Boolean that returns true if a z_score for an internodal measurement is >= 2 or <=-2; useful for quickly identifying images that might need their annotations double checked.
- Internode_x: The length (in centimeters) of the "xth" internode below the primary ear bearing internode.

## Tip

Once the InterMeas algorithm is installed and functional, use [shinyShortcut](https://github.com/cran/shinyShortcut) to create an executable icon to simplify the launch of this workflow.

TODO:
* add slickR to visulize outputs during final internodal measurement step
* add VCA plots back into results section
* add analysis to measure importance of internode lengths in predicting maize phenotypes
* add function to clean potential erronous annotations from periphery of image

