# 03 ANALYSIS WITH THE IMPOSTERS' METHOD

# In order to run this RScript, you need the following:
# - some results of "02_Hyperparameter and Feature Tuning Imposters' Method.R" 
#   saved on your computer
# - the results of "01_Preprocessing.R" in your global environment. (You may 
#   also load the results of said script from your hard drive:
if (file.exists("RData/Results of 01_Preprocessing.RData")) {
  load(file = "RData/Results of 01_Preprocessing.RData")
}

#Before running the imposters' method, we have to find the good results from the
#imposters.optimize() function, saved in different files.

#Prepare a function that takes a data frame such as one of the CSV saved in
#02 HYPERPARAMETER AND FEATURE TUNING, and looks for all rows which fulfill the following
#criteria:
# - None of the P2 values is >= 0.75
# - None of the differences between any P1 and P2 is >= 0.3
# - The difference between p1_avg and p2_avg < 0.2
find.good.params = function(x) {
  results = vector(mode = "numeric", length = 0)
  all_p1 = grepl(pattern = "p1\U002E[0-9]{1,}", x = colnames(good.params))
  all_p2 = grepl(pattern = "p2\U002E[0-9]{1,}", x = colnames(good.params))
  for (i in 1:nrow(x)) {
    if (x[i, "p1.1"] != 0
        && all(x[i, all_p2] < 0.75)
        && all(x[i, all_p2] - x[i, all_p1] < 0.3)
        && x[i, "p2_avg"] - x[i, "p1_avg"] < 0.2)
    results = append(results, i)
  }
  #return the rows of the dataframe which meet the requirements
  return(x[results, ])
}

#Prepare the iteration through all csv files with results of imposters.optimize
list.of.files = list.files(path = "Results_of_imposters.optimize")
good.params = data.frame()

#Iterate through all csv files
for (filename03 in list.of.files) {
  #Read each file from line 4 on
  file03 = read.table(
    file = paste("Results_of_imposters.optimize/", filename03, sep = ""),
    dec = ".",
    sep = ";",
    skip = 3,
    header = TRUE
  )
  
  #Add the file infos to the data frame
  fileinfos = unlist(stri_split_regex(str = filename03, pattern = "-"))
  file03 = cbind(
    base = rep(x = fileinfos[3], times = nrow(file03)),
    level = rep(x = fileinfos[4], times = nrow(file03)),
    n = rep(x = fileinfos[5], times = nrow(file03)),
    file03
  )
  
  #Extract the suitable rows and add them to good.params
  good.params = rbind(good.params, find.good.params(file03))
}

#Name the rows by their number
rownames(good.params) = 1:nrow(good.params)

#Save the good parameters in a file
write.table(
  x = good.params,
  file = paste(
    "Selected_results_of_imposters.optimize_",
    format(Sys.time(), format = "%Y-%m-%d_%H-%M-%S"),
    ".csv",
    sep = ""
  ),
  dec = ".",
  sep = ";",
  row.names = F
)



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

#for (i in 1:nrow(good.params)) {                                               CHANGE BACK!
for (i in c(1)) {
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
           dimnames = list(test.names, c(
             "John", "Luke", "Mark", "Matthew", "Paul"
           )))
  
  #Iterate through all test texts, in order to fill the table "imposters.results"
  for (n in 1:length(test.names)) {
    #Build table of frequencies of training corpus incl. text to be tested
    appended.corpus = training
    appended.corpus[[names(test[n])]] = test[[n]]  #add 1 item of test-->19 items
    appended.word.list = make.frequency.list(appended.corpus)
    freq.table = make.table.of.frequencies(appended.corpus, appended.word.list)
    
    #Split table of frequencies in two
    text.to.be.tested = freq.table[19,]  #the last row
    remaining.texts = freq.table[-19,]   #all other rows
    
    #Fill the results' table by rows: the text to be tested receives a probability
    #for each author candidate
    imposters.results[n,] =
      imposters(
        reference.set = remaining.texts,
        test = text.to.be.tested,
        #1 text as 1 vector of feature frequencies, ordered to match
        #columns of reference set
        iterations = 50,
        distance = "entropy",
        features = 0.5,
        imposters = 0.9
      )
    
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

#While the CSV saved in the for-loops is human-readable, in order to inspect
#the results, the machine-readable version of it will be saved now for further
#processing with "04_Statistical Analysis of the Imposters' method's results.R"
if (dir.exists("RData") == FALSE) {
  dir.create("RData")
}

save(imposters.final.results,
     file = "RData/imposters.final.results.RData")




#Delta on Strong-1-grams with 100-1000 MFW
classify(
  training.corpus = training,
  test.corpus = test,
  classification.method = "delta",
  #default: Burrow's Delta, if not stated otherwise under distance.measure
  distance.measure = "dist.cosine",
  mfw.min = 100,
  mfw.max = 1000,
  mfw.incr = 100,
  corpus.lang = "Other",
  number.of.candidates = 3,
  #Delta:  number of final ranking candidates to be displayed
  final.ranking.of.candidates = TRUE,
  #list misclassified samples in log file
  save.distance.tables = TRUE,
  gui = FALSE
)

#Cross-validation for the above
crossv(
  training.set = read.table("freq_table_primary_set.txt"),
  classification.method = "delta",
  distance.measure = "dist.cosine",
  cv.mode = "leaveoneout"
)