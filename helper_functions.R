#helper functions for main measurement script

cropper_function <- function(x){
  system(paste("python cropper_v3.py -input", x))
}

annotation_function <- function(yolo_dir, weights_file, cropped_dir){
  system(paste("python ",
               yolo_dir,
               "detect.py --weights ", weights_file,
               " --source ", cropped_dir,
               " --img-size 1632 --device 0 --save-txt --nosave --iou-thres 0.2",
               " --project ",
               cropped_dir,
               " --exist-ok",
               sep = ""))
  #make a classes.txt file for verification
  fileConn<-file("Resized_Outputs/exp/labels/classes.txt")
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
  annotation_info$Stalk_number<-annotation_info %>% 
    group_by(annotation_id) %>% 
    group_indices(annotation_id)

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
           Total_Internodes = length(annotation_id)-1)
  
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

  #widen data
  wide_data<- annotation_info %>%
  group_by(annotation_id) %>%
  spread(Internode, Distance) %>% summarize(across(everything(), ~ first(na.omit(.))))
  colnames(wide_data)[13:length(wide_data)]<-paste("Internode", colnames(wide_data)[13:length(wide_data)], sep = "_")
  wide_data$Node<-NULL
  
  #write output to file
  openxlsx::write.xlsx(wide_data, "data_output.xlsx")
}