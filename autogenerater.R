#Rscript to run through entire workflow with minimal interaction

#load libraries required for shiny app

if (!require("pacman")) install.packages("pacman")
pacman::p_load(DT,
               reticulate,
               openxlsx,
               tidyverse,
               rstudioapi)

#make sure wd is set where this file resides
setwd(dirname(getActiveDocumentContext()$path))

#load in configurations
configs <- read.delim("path_info.txt", header = F, sep = " ")
yolo_dir <-trimws(configs[2,1])
labelimg_location <- trimws(configs[3,1])
weights_file <- trimws(configs[4,1])
#username <- Sys.info()["user"][[1]]
#input_directory <- "example_images/"

#setup python environments
#reticulate::use_python(paste0("C:/Users/",username,"/anaconda3/envs/InterMeas/python.exe"), required = T)
reticulate::use_python(trimws(read.delim("path_info.txt", header = F)[1,1]))
reticulate::use_condaenv("InterMeas", required = T)
#py_config()#check environment was setup correctly

#initialize libraries for script and add yolo path 
py_run_file("python_libraries.py") 

#load helper functions
source("helper_functions.R")

#run script using input directory of images specified in response
response <- ""
while (response == "") {
  response <- readline("Crop images (name of target directory) or skip (s)?: ")
  
  if (tolower(response) == "s") { #skip
    message("Skipping cropping step")
  } else {
    if (dir.exists(response)) { #use target directory for cropping
      message("Cropping now...")
      cropper_function(response)
    } else {
      message("The specified directory does not exist.")
      response <- ""  #reset response to prompt again
    }
  }
}

#prompt for annotation section after previous section finishes
response <- ""
while (response == "") {
  response <- readline("Do you require automated annotation? (cpu/gpu/s/<directory_name>): ")
  
  if (tolower(response) == "cpu") { #continue annotations using cpu
    message("You selected cpu annotation of previous output directory'.")
    annotation_function(cropped_dir = "Resized_Outputs/",
                        weights_file = weights_file,
                        yolo_dir = yolo_dir,
                        acceleration = "CPU", 
                        project = "Resized_Outputs/")
  } else if (tolower(response) == "gpu") { #continue annotations using gpu
    message("You selected gpu annotation of previous output directory'.")
    annotation_function(cropped_dir = "Resized_Outputs/",
                        weights_file = weights_file,
                        yolo_dir = yolo_dir,
                        acceleration = "GPU", 
                        project = "Resized_Outputs/")
  } else if (dir.exists(response)) { #continue annotations using gpu and a new target directory
    current_target_directory <- paste0(response,"/") #save response for later
    message(paste0("Starting annotation of images in ",response,"/."))
    annotation_function(cropped_dir = paste0(response,'/'),
                        weights_file = weights_file,
                        yolo_dir = yolo_dir,
                        acceleration = "GPU", 
                        project = paste0(response,'/'))
  } else if (tolower(response) == "s") {
    message("Skipping annotation.")
  } else {
    message("Invalid selection, do you require automated annotation? (cpu/gpu/s/<directory_name>): ")
    response <-""
  }
}

#prompt for verification section
response <- ""
while (response == "") {
  response <- readline("Do you require manual verification using labelImg? (y/s/<directory_name>): ")
  
  if (tolower(response) == "y") {
    message("Verifying previous output directory'.")
    verification_function(cropped_dir = "Resized_Outputs/",
                          labelimg_location = labelimg_location)
  } else if (dir.exists(response)) {
    message(paste0("Starting verification of images in ",response,"/."))
    verification_function(cropped_dir = paste0(response,'/'),
                          labelimg_location = labelimg_location)
  } else if (tolower(response) == "s") {
    message("Skipping verification")
  } else {
    message("Invalid selection, do you require manual verification using labelImg? (y/s/<directory_name>): ")
    response <-""
  }
}

#prompt for details file creation and/or final output creation
response <- ""
while (response == "") {
  if (file.exists("details_file.csv")) {
    followup <- readline(paste0("Previous details_file.csv already exists!\nContinue ('c') and use it\nOR\nGenerate a new one by entering a target directory name(<directory_name>): "))
    if (followup == 'c'){
      analysis_function("Resized_Outputs/")
      message("data_output.xlsx generated")
      response <- "done"
    } else if (dir.exists(followup)){
      prep_function(cropped_dir = paste0(followup,"/"),
                  start_point = as.numeric(readline("Where should id parsing start for group id in filename?\nUse '1' if it's the first character in the filenames:")),
                  stop_point = as.numeric(readline("Where should id parsing end for group id in filename?\nUse'10' if it's the 10th character in the filenames:")))
    verification_function(paste0(followup,"/")) #this is fine for now, details_file.csv is rewritten when it's generated in previous prep_function call
    response <- "done"
  } else {
    message("Please specify an appropriate directory or press 'c' to continue w/ existing details_file.csv: ")
    response <-""
  }
  }
    else {
      followup <- readline("Specify a directory name ready for internode measurement (<directory_name>): ")
      if (dir.exists(followup)){
        message("Prepping details_file.csv...")
        prep_function(cropped_dir = paste0(followup,"/"),
                    start_point = as.numeric(readline("Where should id parsing start for group id in filename; use '1' if it's the first character in the filenames:")),
                    stop_point = as.numeric(readline("Where should id parsing end for group id in filenames; use'10' if it's the 10th character in the filenames:")))
        message("details_file.csv generated; generating internode measurements now...")
        analysis_function(cropped_dir = paste0(followup,"/")) #this is fine for now, details_file.csv is rewritten when it's generated in previous prep_function call
        response <- "done"
    } else {
      message("Please specify an appropriate directory or press 'c' to continue w/ existing details_file.csv: ")
      response <-""
    }
  }
}

#prompt for collection into a single directory
response <- ""
while (response == "") {
  response <- readline("Finished - put all outputs into a single directory? (y/n): ")
  
  if (tolower(response) == "y") {
    current_count <- sum(grepl(Sys.Date(), list.dirs(recursive = F)))
    new_dir <- paste0(Sys.Date(),"_",current_count + 1)
    dir.create(new_dir)
    for (file_name in c("details_file.csv","data_output.xlsx","Resized_Outputs/")) {
      file.rename(from = file_name, 
                  to = paste0(new_dir, "/", file_name))
    }
    message(paste0("Moved files and resized images to: ",new_dir, "/"))
  } else if (tolower(response) == "n") {
    message("Skipping file cleanup...")
  } else {
    message("Invalid selection, put all outputs into a single directory? (y/n): ")
    response <-""
  }
}
