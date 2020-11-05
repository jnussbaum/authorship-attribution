#02-2 PREVIEW TUNING RESULTS

#Since the calculation of the imposters.optimize tables can take very long, this
#script helps you to get a preview of the ongoing calculation, while RStudio is
#busy. To do so, execute the following script as local job: 
#Go to the "Jobs" tab in the bottom left area of RStudio,
#click on "Start Local Job", then select the said R-Script, and check the box 
#"Run job with copy of global environment". Important: Under "Copy job results",
#leave the default "Don't copy" as it is. 

#Create a string with the current date and time
preview_time = format(Sys.time(), format = "%Y-%m-%d_%H-%M-%S")

#Create name of the file to be written
preview_filename = paste("03_Output/Data/Results_of_imposters.optimize/", 
                         "imposters.optimize-",
                         i,
                         "-",
                         paste(t(as.matrix(features[i,])), collapse = "-"), 
                         "-gram_preview_",
                         preview_time,
                         ".csv",
                         sep = "")

#Create file header with some control information
preview_control.information = data.frame(
  c("Feature combination of this file:",
    "Beginning of first training text (1John) is:",
    "Beginning of first test text (Ephesians) is:"),
  c(paste(t(as.matrix(features[i,])), collapse = "-"),
    paste(training[[1]][1:10], collapse = "  -  "),
    paste(test[[1]][1:10], collapse = "  -  ")
  )
)

#Create a new file with the file header. Note that depending on
#your system locale, you have to change the sep and dec parameters, 
#or use write.csv() or write.csv2() instead. The following settings work for
#Microsoft Excel on Windows 10 with locale de-CH.
#If your Excel doesn't display the data correctly, select the first column, 
#go to the tab "Data", and click on "Text to Columns". Select "Delimited", 
#then the Delimiter "Semicolon"
write.table(
  x = preview_control.information,
  file = preview_filename,
  dec = ".",
  sep = ";",
  col.names = F,
  row.names = F
)

#Write the finished imp.params table into the file
write.table(x = imp.params, 
            file = preview_filename,
            append = T,
            dec = ".",
            sep = ";",
            row.names = F)
