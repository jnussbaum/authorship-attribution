# 03 ANALYSIS WITH THE IMPOSTERS' METHOD

# In order to run this RScript, you need the following:
# - some results of "02_Hyperparameter and Feature Tuning Imposters' Method.R" 
#   saved on your computer
# - the results of "01_Preprocessing.R" in your global environment. (You may 
#   also load the results of that script from your computer:
if (file.exists("03_Output/Data/Results_of_01_Preprocessing.RData")) {
  load(file = "03_Output/Data/Results_of_01_Preprocessing.RData")
}

#Check dependencies
if(require("stylo") == FALSE) {
  install.packages("stylo")
  library("stylo")
}
if(require("data.table") == FALSE) {
  install.packages("data.table")
  library("data.table")
}
if(require("stringi") == FALSE) {
  install.packages("stringi")
  library("stringi")
}
source("02_Script/Functions/01_check_p1_p2_constraints.R")

#Before running the imposters' method, we have to find the good results from the
#imposters.optimize() function, saved in different files.
#Prepare the iteration through all csv files with results of imposters.optimize
list.of.files = list.files(path = "03_Output/Data/Results_of_imposters.optimize")
good.params = data.frame()

#Iterate through all csv files
for (filename03 in list.of.files) {
  #Read each file from line 4 on
  file03 = read.table(
    file = paste("03_Output/Data/Results_of_imposters.optimize/", filename03, sep = ""),
    dec = ".",
    sep = ";",
    skip = 3,
    header = TRUE
  )
  
  #Add the file info to the data frame
  fileinfos = unlist(stri_split_regex(str = filename03, pattern = "-"))
  file03 = cbind(
    base = rep(x = fileinfos[3], times = nrow(file03)),
    level = rep(x = fileinfos[4], times = nrow(file03)),
    n = rep(x = fileinfos[5], times = nrow(file03)),
    file03
  )
  
  #Create an index of the suitable rows
  found.lines.index = vector(mode = "logical", length = 0)
  for (i in 1:nrow(file03)) {
    #Add TRUE or FALSE to found.lines, depending on the result of the  
    #constraints-check for the line in question
    line.result = check_p1_p2_constraints(file03[i,])
    found.lines.index = append(found.lines.index, line.result)
  }
  #Add the to good.params
  good.params = rbind(good.params, file03[found.lines.index,])
}

#Name the rows by their number
rownames(good.params) = 1:nrow(good.params)

#Set filename where to save the results of the actual analysis
filename03 = paste("Results_of_Imposters_Method_",
             format(Sys.time(), format = "%Y-%m-%d_%H-%M-%S"),
             ".csv",
             sep = "")

#Now that the good parameters are found, the actual analysis can start. To do so,
#iterate through the rows of good.params, and for each row, execute the imposters'
#method with this row's parameters. Save the results in one file.

#Prepare a 3-dimensional array for the final results
imposters.final.results = 
  array(dim = c(length(test.names), 
                length(candidates), 
                nrow(good.params)
                ),
        dimnames = list(test.names, 
                        candidates,
                        param.config = NULL
                        ))

for (i in 1:nrow(good.params)) {
  #First, load the corpora with the specifications of the current row in good.params
  test =
    parse.corpus(
      input.data = eval(parse(
        text = paste("test.corpus.",
                     good.params[i, "base"],
                     sep = "")
      )),
      splitting.rule = " ",
      features = good.params[i, "level"],
      ngram.size = as.numeric(good.params[i, "n"])
    )
  
  training =
    parse.corpus(
      input.data = eval(parse(
        text = paste("training.corpus.",
                     good.params[i, "base"],
                     sep = "")
      )),
      splitting.rule = " ",
      features = good.params[i, "level"],
      ngram.size = as.numeric(good.params[i, "n"])
    )
  
  #Prepare an empty table for the results
  imposters.results =
    matrix(nrow = length(test.names),
           ncol = length(candidates),
           dimnames = list(test.names, candidates))
  
  #Iterate through all test texts, in order to fill the table "imposters.results"
  for (n in 1:length(test.names)) {
    #Build table of frequencies of training corpus incl. text to be tested
    appended.corpus = training
    appended.corpus[[names(test[n])]] = test[[n]]  #add 1 item of test
    appended.word.list = make.frequency.list(appended.corpus)
    freq.table = make.table.of.frequencies(appended.corpus, appended.word.list)
    
    #Split table of frequencies in two
    text.to.be.tested = freq.table[length(appended.corpus),]  #the last row
    remaining.texts = freq.table[-length(appended.corpus),]   #all other rows
    
    #Fill the results' table by rows: the text to be tested receives a probability
    #for each author candidate
    imposters.results[n,] =
      imposters(
        reference.set = remaining.texts,
        test = text.to.be.tested,
        iterations = 50,
        distance = good.params[i, "dist"],
        features = good.params[i, "feat"],
        imposters = good.params[i, "imp"]
      )
    
    #Set the insignificant values (inside the range p1-p2) to NA
    insignificant = data.table::inrange(x = imposters.results[n,], 
                        lower = good.params[i, "p1_avg"],
                        upper = good.params[i, "p2_avg"])
    imposters.results[n, insignificant] = NA
    
    #Make a copy of the above in the final results' array
    imposters.final.results[n, , i] = imposters.results[n,]
  }
  
  #Write the resulting table into the file, first adding some metainformation
  write.table(x = good.params[i, c(1:6, 19:20)],
              file = filename03,
              dec = ".",
              sep = ";",
              col.names = T,
              row.names = F,
              append = T)
  write.table(x = imposters.results,
              file = filename03,
              dec = ".",
              sep = ";",
              append = T,
              col.names = NA,
              row.names = T)
  #Adding two blank lines
  write.table(x = matrix(data = c(" ", " "), nrow = 2, ncol = 1),
              file = filename03,
              dec = ".",
              sep = ";",
              col.names = F,
              row.names = F,
              append = T)
}

#While the CSV saved in the for-loops is human-readable, the machine-readable
#version of it will be saved now for further processing with 
#04 STATISTICAL ANALYSIS OF THE IMPOSTERS' METHOD'S RESULTS
save(imposters.final.results,
     file = "03_Output/Data/imposters.final.results.RData")
