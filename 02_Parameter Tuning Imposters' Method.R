# 02 PARAMETER TUNING FOR THE IMPOSTERS' METHOD


#Find out systematically which combinations of features and tuning parameters
#provide the best results. In order to do this, 
# 1. define the combinations of features to evaluate
# 2. Define the combinations of values for the parameters "distance", "features",
#    and "imposters",
# 3. iterate through all rows of the dataframe "features". In every iteration, 
#    load the respective corpora, and then create a table with p1 and p2 values 
#    for different combinations of tuning parameters. After manual inspection 
#    of these tables, the actual analysis can be run with the best tuning 
#    parameters.

#The resulting tables are saved as CSV in a separate folder in the working
#directory.
dir.create(paste(getwd(), "/Results_of_imposters.optimize", sep = ""))

#When P1 and P2 are close to each other, the chosen values for dist, feat,
#and imp are likely to be good. But since there are random factors involved in
#the calculation of P1 and P2, they won't have the same value if they are 
#calculated two times in a row. Thus it is advised to calculate them several 
#times, and then take the arithmetic mean of them.
#Choose number of iterations (how many times p1 and p2 are calculated):
iterations = 6

#Define feature combinations, by creating a data frame in which every row
#is another combination of features
features = expand.grid(c("Strong", "POS_S"),
                       "w",
                       1:3)

features = rbind(features, expand.grid("Greek",
                                       c("w", "c"),
                                       1:3))

features = rbind(features, expand.grid("POS_L",
                                       "w",
                                       1))

colnames(features) = c("base", "level", "n")


#Define the combinations of values for the three parameters "distance", 
#"features", and "imposters", by creating a dataframe in which every row 
#contains another combination to test.
imp.params = expand.grid(dist = c("cosine", "entropy", "canberra"),
                         feat = c(.1, .25, .5, .75, .9),
                         imp  = c(.1, .25, .5, .75, .9))

#Calculate the column names for the p1 and p2 values
col.names = vector(mode = "character", length = 2*iterations + 2)
p_columns = expand.grid(c("p1.", "p2."),
                        1:iterations)
for (its in 1:(2*iterations)) {
   col.names[its] = paste(t(as.matrix(p_columns[its,])), collapse = "")
}
col.names[2*iterations + 1] = "p1_avg"
col.names[2*iterations + 2] = "p2_avg"

#Add empty columns for the p1 and p2 values
imp.params =
   cbind(imp.params,
         matrix(
            vector(
               mode = "numeric",
               length = (2 * iterations + 2) * nrow(imp.params)
            ),
            nrow = nrow(imp.params),
            ncol = 2 * iterations + 2,
            dimnames = list(
               rownames = c(1:nrow(imp.params)),
               colnames = col.names
            )
         ))

#Iterate through all rows of features
for (i in 6:nrow(features)) {
   
   #Make sure that imp.params contains no old values
   for (j in 1:nrow(imp.params)) {
      for (k in 4:ncol(imp.params)) {
         imp.params[j,k] = 0
      }
   }
   
   #Load the corpora of the features of the actual iteration
   test =
      parse.corpus(
         input.data = eval(parse(text = paste("test.corpus.", 
                                              features[i, "base"], 
                                              sep = ""))),
         splitting.rule = " ",
         features = features[i, "level"],
         ngram.size = features[i, "n"]
      )
   
   training =
      parse.corpus(
         input.data = eval(parse(text = paste("training.corpus.", 
                                              features[i, "base"], 
                                              sep = ""))),
         splitting.rule = " ",
         features = features[i, "level"],
         ngram.size = features[i, "n"]
      )
   
   training.word.list = make.frequency.list(training)
   training.freq.table = make.table.of.frequencies(training, training.word.list)
   
   p1_vals = vector(mode = "numeric", length = iterations)
   p2_vals = vector(mode = "numeric", length = iterations)
   
   for (j in 1:nrow(imp.params)) {
      for (k in 1:iterations) {
         imp.opt.res = imposters.optimize(
            reference.set = training.freq.table,
            parameter.incr = 0.05,
            distance = imp.params[j, "dist"],
            features = imp.params[j, "feat"],
            imposters = imp.params[j, "imp"]
         )
         imp.params[j, 4 + (2 * k) - 2] = imp.opt.res[1]
         imp.params[j, 5 + (2 * k) - 2] = imp.opt.res[2]
         p1_vals[k] = imp.opt.res[1]
         p2_vals[k] = imp.opt.res[2]
      }
      imp.params[j, "p1_avg"] = mean(p1_vals)
      imp.params[j, "p2_avg"] = mean(p2_vals)
   }
   
   #Create name of the file to be written
   filename = paste(getwd(), 
                    "/Results_of_imposters.optimize/",
                    paste("imposters.optimize", 
                          paste(t(as.matrix(features[i,])), 
                                collapse = "-"), 
                          sep = "-"),
                    "-gram.csv",
                    sep = "")
   
   #Create file header with some control information
   control.information = data.frame(
      c("Feature combination of this file:",
        "Beginning of first training text (1John) is:",
        "Beginning of first test text (1Timothy) is:"),
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
      x = control.information,
      file = filename,
      dec = ".",
      sep = ";",
      col.names = F,
      row.names = F
   )
   
   #Write the finished imp.params table into the file
   write.table(x = imp.params, 
             file = filename,
             append = T,
             dec = ".",
             sep = ";",
             row.names = F)
   
}
