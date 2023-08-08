#helper functions for main measurement script

cropper_function <- function(x){
  system(paste("python cropper_v3.py -input", x))
}

annotation_function <- function(yolo_dir, weights_file, cropped_dir,acceleration, project){
  #print(yolo_dir)
  #print(cropped_dir)
  #Convert yolo_dir and cropped_dir to absolute paths
  #yolo_dir <- normalizePath(yolo_dir, mustWork = FALSE)
  #cropped_dir <- normalizePath(cropped_dir, mustWork = FALSE)
  #print(yolo_dir)
  #print(cropped_dir)

  #Run detect.py
  system(paste("python ",
               yolo_dir,
               "detect.py --weights ", weights_file,
               " --source ", cropped_dir,
               paste0(" --img-size 1632 --device ",
                      if (acceleration=="GPU") {"0"}
                      else{"cpu"},
                      " --save-txt --nosave --iou-thres 0.2", sep=""),
               " --project ",
               project,
               " --exist-ok",
               sep = ""))
  
  # Make a classes.txt file for verification
  classes_file <- file.path("Resized_Outputs", "exp", "labels", "classes.txt")
  if (!file.exists(classes_file)) {
    dir.create(dirname(classes_file), recursive = TRUE)
  }
  fileConn <- file(classes_file, open = "w")
  writeLines("node", fileConn)
  close(fileConn)
}

verification_function <- function(labelimg_location, cropped_dir){
  #add line where if classes.txt file doesn't exist - make it
  write.table(x = "node",quote = F, file = paste(cropped_dir,"/exp/labels/classes.txt", sep = ""), col.names = F, row.names = F)
  label_path <- paste("python ",
                     labelimg_location,
                     "labelImg.py ",
                     cropped_dir,
                     #" ",
                     #cropped_dir,"/exp/labels",
                     sep = "")
  system(label_path, invisible = F)
  remove(label_path)
  #remove(annotator)
}

#function to produce image sizes and groupings based on filename
#for grouping, pull file basename and extract string for groupings using start/stop character locations
prep_function <- function(cropped_dir, start_point, stop_point){
  #read in image dimensions
  cv2 <- import("cv2")
  
  image_sizes = data.frame(file_name=character(),
                           group=character(),
                           height=numeric(),
                           width=numeric())
  
  for (i in list.files(cropped_dir, pattern = "\\.jpg$")) {
    image <- cv2$imread(paste(cropped_dir,"/",i, sep = ""))
    file_name <- str_remove(basename(i),".jpg")
    group <- substring(i,start_point,stop_point)
    height <- nrow(image)
    width <- ncol(image)
    image_sizes[nrow(image_sizes)+1,] <- c(file_name, group, height, width)
  }
  
  write.csv(image_sizes, file = "details_file.csv", row.names = F)
}

analysis_function <- function(cropped_dir){
  #read yolo label filepaths into a list
  all_files <- list.files(path = paste(cropped_dir, "/exp/labels", sep = ""), full.names = T)# same as above, but original yolo output for labelimg verification

  #drop classes.txt file from both lists
  all_files<- all_files[str_detect(all_files, "classes.txt")=="FALSE"] #drop the classes file

  #empty files cause errors to be thrown by read.delim; remove empty annotation
  all_files <- all_files[which(lapply(all_files, file.size)>0)]#keep only files w/ annotations

  #read in node locations for each stalk
  thefilelist <- data.table::rbindlist(lapply(all_files, data.table::fread, sep = " ", header = F, select=c(2,3)), idcol = "annotation_id")
  thefilelist[, annotation_id:= factor(annotation_id, labels = str_remove(basename(all_files), ".txt"))]
  
  #generate another list of filenames for reference later
  thefilenames <- lapply(all_files, basename) %>%
    str_remove(".txt") %>% as.data.frame()

  #read in image dimensions from details_file
  image_dimensions <- read.csv("details_file.csv")
  
  #merge image dimensions and annotation info
  annotation_info <- data.table::merge.data.table(x = thefilelist, y = image_dimensions, by.x = "annotation_id", by.y = "file_name")
  names(annotation_info)[2:3]<-c("x_pos","y_pos")

  #add identifier for stalk number in dataset
  annotation_info<-transform(annotation_info,
                             Stalk_number = as.numeric(factor(annotation_id)))

  #sort vertically by stalk
  annotation_info <- annotation_info %>% arrange(annotation_info$annotation_id,-annotation_info$y_pos)

  #convert node x and y positions to pixel locations
  annotation_info$x_pos<-round(annotation_info$x_pos*annotation_info$width)
  annotation_info$y_pos<-round(annotation_info$y_pos*annotation_info$height)

  #calc distance to next node
  #blue backmat is 36 inches wide; image cropped at outlines of blue backmat, use image width for conversion
  annotation_info$converter <- annotation_info$width/(36*2.54) #pixels/cm
  
  #add internode identifiers
  annotation_info <- annotation_info %>%
    group_by(annotation_id) %>%
    mutate(Node = row_number(),
           Internode = Node-1,
           Total_Internodes = length(annotation_id)-1,
           Pixel_Distance = NA)
  
  #eucledian distance calcs
  for(i in 1:nrow(annotation_info)) {
    if(i > 1 && annotation_info$annotation_id[i] == annotation_info$annotation_id[i-1]) {#ignore first node, measure dist between down-stalk node + 1 above it within same stalks only
      annotation_info$Pixel_Distance[i] <- sqrt(((annotation_info$x_pos[i] - annotation_info$x_pos[i-1]) ^ 2) + ((annotation_info$y_pos[i] - annotation_info$y_pos[i-1]) ^ 2)) #pythagorean coord calc
    } else {
      annotation_info$Pixel_Distance[i] <- NA #if first node, add NA; remove these later they're placeholders/references for first internode measurements
    }
  }
  
  #convert pixel distance to cm scale
  annotation_info<-annotation_info[!is.na(annotation_info$Pixel_Distance),]
  annotation_info$Distance <- annotation_info$Pixel_Distance/annotation_info$converter

  #pivot the data wider to collapse internode measures into a single column
  annotation_info$Internode<-factor(annotation_info$Internode, levels = c(1:length(unique(annotation_info$Internode))))
  annotation_info$Sum_Internodes <- ave(annotation_info$Distance, annotation_info$annotation_id, FUN=sum)
  z_score <- annotation_info[,c(10,13)] %>%
      group_by(Internode) %>%
      mutate(z_score = (Distance - mean(Distance))/sd(Distance)) %>% 
      ungroup() %>%
      select(z_score) %>% unlist() %>% unname()
  
  annotation_info$z_score <- z_score
  
  #Identify outliers; 2x the z-score ~95% confidence interval for a normally distributed dataset
  annotation_info$outliers <- annotation_info$z_score >= 2 | annotation_info$z_score <= -2

  #widen data
  wide_data<- annotation_info %>%
    group_by(annotation_id) %>%
    mutate(max_z_score = ifelse(abs(z_score) == max(abs(z_score)), z_score, NA)) %>%
    tidyr::fill(max_z_score) %>%
    spread(Internode, Distance) %>%
    summarize(across(everything(), ~ first(na.omit(.))))
  colnames(wide_data)[16:length(wide_data)]<-paste("Internode", colnames(wide_data)[16:length(wide_data)], sep = "_")
  wide_data$Node<-NULL
  wide_data$Pixel_Distance <- NULL

  #write output to file
  openxlsx::write.xlsx(wide_data, "data_output.xlsx")
}

chunking_function <- function(directory){
  #Get the list of files in the directory
  files <- list.files(directory, full.names = TRUE)
  
  temp_dirs <- lapply(1:5, function(i) {
    dir_name <- paste0(tempdir(), "/temp_dir_", i)
    dir.create(dir_name, recursive = TRUE)
    dir_name
  })
  
  #Calculate the number of files to process (1/5th of total files)
  numFilesToProcess <- ceiling(length(files) / 5)
  
  #Create symbolic links to files in each temporary directory
  lapply(seq_along(temp_dirs), function(i) {
    start_index <- (i - 1) * numFilesToProcess + 1
    end_index <- min(start_index + numFilesToProcess - 1, length(files))
    temp_files <- files[start_index:end_index]
    
    lapply(temp_files, function(file) {
      link_name <- file.path(temp_dirs[[i]], basename(file))
      file.link(file, link_name)
    })
  })
  return(temp_dirs)
}
