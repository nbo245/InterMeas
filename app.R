#shiny app for using yolo object detection algo to measure internode lengths in
#maize stalks

#setwd("d:/2021_image_analysis/shiny_annotator_end_of_summer/shiny_annotator/")
#load libraries required for shiny app

if (!require("pacman")) install.packages("pacman")
pacman::p_load(shiny,
               #jpeg,
               #fs,
               shinydashboard,
               shinyFiles,
               slickR,
               #flexdashboard,
               DT,
               reticulate,
               openxlsx,
               #shinyWidgets,
               waiter,
               VCA,
               #rhandsontable,
               #ggvis, 
               tidyverse)

#load in configurations
configs <- read.delim("configs_mod.txt", header = F, sep = " ")
yolo_dir <-trimws(configs[5,2])
labelimg_location <- trimws(configs[6,2])
weights_file <- trimws(configs[7,2])
username <- trimws(configs[8,2])

#setup python environments
reticulate::use_python(paste0("C:/Users/",username,"/anaconda3/envs/InterMeas/python.exe"), required = T)
reticulate::use_condaenv("InterMeas", required = T)
#py_config()#check environment was setup correctly

#initialize libraries for script and add yolo path 
py_run_file("python_libraries.py") 

#load helper functions
source("helper_functions.R")

ui <- dashboardPage(
  dashboardHeader(title = "InterMeas"),
  dashboardSidebar(
    sidebarMenu(id = "sidebar",
                menuItem("Inputs", tabName = "inputs", icon = icon("file-upload")),
                menuItem("Results", tabName = "results", icon = icon("table")))),
  dashboardBody(
    tabItems(
      # Dashboard layout for Inputs screen
      tabItem(tabName = "inputs",
              fluidRow(
                useWaitress(),
                box(
                  title = "1) Start Here!", status = "primary", solidHeader = TRUE, width = 4,
                  style = "height:300px; overflow-y: scroll;",
                  h1("Input Directory"),
                  tags$p("Please select the directory containing the original images.  After selecting directory, click the 'Run Cropping Script' button below."),
                  shinyDirButton(title = "Select folder with Images that need to be cropped", id = "cropper_browse", label = "Original images", multiple =F),
                  #useWaitress(),
                  br(),
                  actionButton("cropper_button", label = "Run Cropping Script."),
                  h5(textOutput("selected_orig_image_path"))),
                box(
                  title = "2) Annotate the cropped images", status = "primary", solidHeader = TRUE, width = 4,
                  style = "height:300px; overflow-y: scroll;",
                  h1("Cropped Directory"),
                  tags$p("Select the directory containing the cropped images you'd like to annotate.  Make sure all images in directory contain a single, inverted stalk (bottom of stalk should be at top of image).  Once selected, click the 'Run Annotation Script' button below."),
                  shinyDirButton(title = "Select folder containing cropped images", id = "annotation_browse", label = "Cropped Image Location.", multiple =F),
                  selectInput(inputId = "acceleration", label = "If GPU acceleration is available, select GPU: ", choices = c("CPU","GPU"), selected = "GPU", multiple = F),
                  useWaitress(),
                  actionButton("annotation_button", label = "Run Annotation Script."),
                  h5(textOutput("selected_annot_image_path"))),
                box(
                  title = "3) Verify that image annotation was successful", status = "primary", solidHeader = TRUE, width = 4,
                  style = "height:300px; overflow-y: scroll;",
                  h1("Cropped Directory"),
                  tags$p("Select the directory containing the cropped images you've already annotated.  Annotation will be located within the Resized_Outputs folder under exp/labels.  Once selected, click the 'Verify Labels' button below."),
                  shinyDirButton(title = "Select folder containing cropped images", id = "verification_browse", label = "Cropped Image Location.", multiple =F),
                  actionButton("verification_button", label = "Verify Labels"),
                  h5(textOutput("selected_label_path"))),
                box(
                  title = "4) Prep for Final Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  #style = "height:270px; overflow-y: scroll;",
                  h1("Labels in Cropped directory"),
                  tags$p("Select the directory containing the verified labels from previous annotation step.  Once selected, click the 'Make Details File' button below."),
                  shinyDirButton(title = "Select folder containing cropped images", id = "cropped_images_path", label = "Cropped Image Location.", multiple =F),
                  numericInput(inputId = "start_point",label = "ID Start",value = 1, min = 1),
                  numericInput(inputId = "end_point",label = "ID End",value = 10, min = 1),
                  actionButton(inputId = "prep_button", label = "Make Details File")),
                box(
                  title = "5) Internodal Measurement", status = "primary", solidHeader = TRUE, width = 6,
                  #style = "height:270px; overflow-y: scroll;",
                  h1("Cropped Directory"),
                  tags$p("Select folder containing cropped images.  Select details file created in previous step.  Press the 'Run Analysis' button to measure internodal lengths in all annotated images."),
                  shinyDirButton(title = "Select folder containing cropped images", id = "analysis_browse", label = "Cropped Image Location.", multiple =F),
                  fileInput(inputId = "details_location", label = "Select details file in main directory.",
                            multiple = F, accept = ".csv", placeholder = "select details file"),
                  actionButton(inputId = "analysis_button", label = "Run Analysis"))
                )
              )
      #add figures in next tab
      # tabItem(tabName = "results",
      #         fluidPage(
      #           useWaitress(),
      #           box(
      #             title = "1) Start something!", status = "primary", solidHeader = TRUE, width = 4,
      #             style = "height:300px; overflow-y: scroll;",
      #             h1("Input Directory"),
      #             tags$p("Please select the directory containing the original images.  After selecting directory, click the 'Run Cropping Script' button below."),
      #             shinyDirButton(title = "Select folder with Images that need to be cropped", id = "cropper_browse", label = "Original images", multiple =F),
      #             #useWaitress(),
      #             br(),
      #             actionButton("cropper_button", label = "Run Cropping Script."),
      #             h5(textOutput("selected_orig_image_path")))))
      )
    )
  )

server <- function(input, output, session) {

  #initialize volume locations
  volumes <- c(InterMeas = getwd(), getVolumes()())

  #browse for files buttons
  shinyDirChoose(input, 'cropper_browse', roots = volumes, session = session)
  shinyDirChoose(input, 'annotation_browse', roots = volumes, session = session)
  shinyDirChoose(input, 'verification_browse', roots = volumes, session = session)
  shinyDirChoose(input, 'analysis_browse', roots = volumes, session = session)
  shinyDirChoose(input, 'cropped_images_path', roots=volumes, session = session)
  
  #what to do if cropper_browse is pressed
  observeEvent(eventExpr = input$cropper_browse, {
    if (!is_empty(input$cropper_browse)){
      output$selected_orig_image_path<- renderPrint({parseDirPath(roots = volumes, input$cropper_browse)
      })
        }},
    ignoreInit = T)
  
  #what to do if cropper_button is pressed
  observeEvent(eventExpr = input$cropper_button, {
    shiny::req(input$cropper_browse)
    if (req(input$cropper_button) > 0) {
      #target directory for cropping
      directory <- parseDirPath(roots = volumes, input$cropper_browse)
      #unlink previously created tempdirs
      unlink(paste0(normalizePath(tempdir()), "/", dir(tempdir())), recursive = TRUE)
      
      #generate new temp dirs using chunking function
      temp_dirs <- chunking_function(directory = directory)
      withProgressWaitress({for (chunk in seq_along(temp_dirs)) {
        cropper_function(temp_dirs[[chunk]])
        #print(list.files(temp_dirs[[chunk]])) #for troubleshooting
        incProgressWaitress(1) #update the progress bar incrementally
      }}, selector = "#cropper_button", max = 10, theme = "overlay-percent")
      }
  })
  
  #what to do if annotation_browse is pressed
  observeEvent(eventExpr = input$annotation_browse, {
    if (!is_empty(input$annotation_browse)){
      output$selected_annot_image_path<- renderPrint({parseDirPath(roots = volumes, input$annotation_browse)
      })
    }},
    ignoreInit = T)
  
  #what to do if annotation_button is pressed
  observeEvent(eventExpr = input$annotation_button, {
    shiny::req(input$annotation_browse)
    if (req(input$annotation_button) > 0) {
      #target directory for annotation
      directory <- parseDirPath(roots = volumes, input$annotation_browse)
      #unlink previously created tempdirs
      unlink(paste0(normalizePath(tempdir()), "/", dir(tempdir())), recursive = TRUE)
      
      #generate new temp dirs using chunking function
      temp_dirs <- chunking_function(directory = directory)
      withProgressWaitress({for (chunk in seq_along(temp_dirs)) {
        annotation_function(cropped_dir = temp_dirs[[chunk]],
                            weights_file = weights_file,
                            yolo_dir = yolo_dir,
                            acceleration = input$acceleration, 
                            project = directory)
        #print(list.files(temp_dirs[[chunk]])) #for troubleshooting
        incProgressWaitress(1) #update the progress bar incrementally
      }}, selector = "#annotation_button", max = 10, theme = "overlay-percent")
    }
  })

  #what to do if verification_browse is pressed
  observeEvent(eventExpr = input$verification_browse, {
    if (!is_empty(input$verification_browse)){
      output$selected_label_path<- renderPrint({parseDirPath(roots = volumes, input$verification_browse)
      })
    }},
    ignoreInit = T)
  
  #what to do if verification_button is pressed
  observeEvent(eventExpr = input$verification_button, {
    shiny::req(input$verification_browse)
    if (req(input$verification_button) > 0) {
      verification_function(cropped_dir = parseDirPath(roots = volumes, input$verification_browse),
                          labelimg_location = labelimg_location)
    }
  })
  
  #what to do if prep_button is pressed
  observeEvent(eventExpr = input$prep_button, {
    if (req(input$prep_button) > 0) {
      waitress <- Waitress$new("#prep_button", theme = "overlay", infinite = TRUE)
      waitress$start()
      prep_function(cropped_dir = parseDirPath(roots = volumes, input$cropped_images_path),
                    start_point = input$start_point,
                    stop_point = input$end_point)
      waitress$close()
    }
  })
  
  #what to do if analysis_browse is pressed
  observeEvent(eventExpr = input$analysis_browse, {
    if (!is_empty(input$analysis_browse)){
      output$selected_analysis_path<- renderPrint({parseDirPath(roots = volumes, input$analysis_browse)
      })
    }},
    ignoreInit = T)

  #what to do if analysis_button is pressed
  observeEvent(eventExpr = input$analysis_button, {
    shiny::req(input$analysis_browse)
    if (req(input$analysis_button) > 0) {
      waitress <- Waitress$new("#analysis_button", theme = "overlay", infinite = TRUE)
      waitress$start()
      analysis_function(cropped_dir = parseDirPath(roots = volumes, input$analysis_browse))
      waitress$close() # hide when done
    }
  })
 }

#run the app
shinyApp(ui, server)
