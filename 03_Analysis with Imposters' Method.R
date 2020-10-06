# 03 ANALYSIS WITH THE IMPOSTERS' METHOD

#Before running the imposters' method, we have to find the good results from the
#imposters.optimize() function, saved in different files.

#Prepare a function that takes a data frame such as one of the CSV saved in 
#02 PARAMETER TUNING, and looks for all rows which fulfill the following
#criteria:
# None of the P2 values is >= 0.75
# None of the differences between any P1 and P2 is >= 0.3
# The difference between p1_avg and p2_avg < 0.2
find.good.params = function(x) {
  results = vector(mode = "numeric", length = 0)
  for (i in 1:nrow(x)) {
    if(x[i, "p2.1"] < 0.75 &&
       x[i, "p2.2"] < 0.75 &&
       x[i, "p2.3"] < 0.75 &&
       x[i, "p2.4"] < 0.75 &&
       x[i, "p2.5"] < 0.75 &&
       x[i, "p2.6"] < 0.75 &&
       x[i, "p2.1"] - x[i, "p1.1"] < 0.3 &&
       x[i, "p2.2"] - x[i, "p1.2"] < 0.3 &&
       x[i, "p2.3"] - x[i, "p1.3"] < 0.3 &&
       x[i, "p2.4"] - x[i, "p1.4"] < 0.3 &&
       x[i, "p2.5"] - x[i, "p1.5"] < 0.3 &&
       x[i, "p2.6"] - x[i, "p1.6"] < 0.3 &&
       x[i, "p2_avg"] - x[i, "p1_avg"] < 0.2)
      results = append(results, i)
  }
  #return the rows of the dataframe which meet the requirements
  return(x[results,])
}

#Prepare the iteration through all csv files with results of imposters.optimize
list.of.files = list.files(path = paste(getwd(), 
                                        "/Results_of_imposters.optimize", 
                                        sep = ""))
good.params = data.frame()

#Iterate through all csv files
for (filename in list.of.files) {
  
  #Read each file from line 5 on
  file = read.table(
    file = paste(getwd(), "/Results_of_imposters.optimize/", filename, sep = ""),
    dec = ".",
    sep = ";",
    skip = 4,
    header = FALSE,
    col.names = c("dist","feat","imp","p1.1","p2.1","p1.2","p2.2","p1.3","p2.3",
                  "p1.4","p2.4","p1.5","p2.5","p1.6","p2.6","p1_avg","p2_avg")
  )
  
  #Add the file infos to the data frame
  fileinfos = unlist(stri_split_regex(str = filename, pattern = "-"))
  file = cbind(
    base = rep(x = fileinfos[2], times = nrow(file)),
    level = rep(x = fileinfos[3], times = nrow(file)),
    n = rep(x = fileinfos[4], times = nrow(file)),
    file)
  
  #Extract the suitable rows and add them to good.params
  good.params = rbind(good.params, find.good.params(file))
}

#Name the rows by their number
rownames(good.params) = 1:nrow(good.params)

#Save the good parameters in a file
write.table(x = good.params,
            file = paste(getwd(), 
                         "/Results_of_imposters.optimize/Good_parameters.csv", 
                         sep = ""))



#Now that the good parameters are found, the actual analysis can start. To do so,
#iterate through the rows of good.params, and for each row, execute the imposters'
#method with this row's parameters. Save the results in one file.
for (i in 1:nrow(good.params)) {
  
  #First, load the corpora with the specifications of the actual row in good.params
  test =
    parse.corpus(
      input.data = eval(parse(text = paste("test.corpus.", 
                                           good.params[i, "base"], 
                                           sep = ""))),
      splitting.rule = " ",
      features = good.params[i, "level"],
      ngram.size = good.params[i, "n"]
    )
  
  training =
    parse.corpus(
      input.data = eval(parse(text = paste("training.corpus.", 
                                           good.params[i, "base"], 
                                           sep = ""))),
      splitting.rule = " ",
      features = good.params[i, "level"],
      ngram.size = good.params[i, "n"]
    )

  #Prepare an empty table for the results
  imposters.results =
    matrix(nrow = 10,
           ncol = 5,
           dimnames = list(test.names, c("John", "Luke", "Mark", "Matthew", "Paul")))

  #Iterate through all test texts, in order to fill the table "imposters.results"
  for (n in 1:10) {
    #Build table of frequencies of training corpus incl. text to be tested
    appended.corpus = rbind(training, test[[n]])  #appended.corpus has 19 rows
    appended.word.list = make.frequency.list(appended.corpus)
    freq.table = make.table.of.frequencies(appended.corpus, appended.word.list)
    
    #Split table of frequencies in two
    text.to.be.tested = freq.table[19, ]  #the last row
    remaining.texts = freq.table[-19, ]   #all other rows
    
    #Fill the results' table by rows: the text to be tested receives a probability
    #for each author candidate
    imposters.results[n, ] =
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
  }
  
  #Write the resulting table into the file, first adding some metainformation
  write.table(x = good.params[i,],
              file = "Results of Imposters' Method.xls",
              append = T)
  write.table(x = imposters.results,
              file = "Results of Imposters' Method.xls",
              append = T)
  #Adding a blank line
  write.table(x = matrix(nrow = 2, ncol = 10),
              file = "Results of Imposters' Method.xls",
              append = T)
}

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