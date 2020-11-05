# 02 HYPERPARAMETER AND FEATURE TUNING FOR THE IMPOSTERS' METHOD

#In order to run this RScript, you first need to run "01_Preprocessing.R". 
#You may also load the results of that script from your computer
if (file.exists("03_Output/Data/Results_of_01_Preprocessing.RData")) {
   load(file = "03_Output/Data/Results_of_01_Preprocessing.RData")
}

#Check dependencies
if(require("stylo") == FALSE) {
   install.packages("stylo")
   library("stylo")
}
source("02_Script/Functions/01_check_p1_p2_constraints.R")

#This RScript performs a grid search for the best combinations of features and
#hyperparameters for the Imposters' Method. A grid search means to
#systematically go through all possible combinations and to estimate how well
#they will perform. The programmers of the package "stylo" provide the function
#imposters.optimize() which can be called with specific features and
#hyperparameters. The function imposters.optimize() then returns a P1 and P2
#value, in between which the results of imposters() will be unreliable, when
#called with exactly the same features and hyperparameters. If the range between
#P1 and P2 is small and close to 0.5, the choice of the features and
#hyperparameters is likely to be a good one.
#In order perform the grid search, 
# 1. Define the combinations of features to evaluate
# 2. Define the combinations of values for the hyperparameters "distance", 
#    "features", and "imposters",
# 3. iterate through all combinations of features. In every iteration, 
#    load the respective corpora, and then create a table with p1 and p2 values 
#    for different combinations of hyperparameters.

#Since there are random factors involved in the calculation of P1 and P2, they
#won't have the same value if they are calculated two times in a row. Thus it is
#advised to calculate them several times, and then take the arithmetic mean.
#Choose number of iterations (how many times p1 and p2 are calculated):
iterations = 6

#The resulting tables are saved as CSV in the following folder:
if (!dir.exists("03_Output/Data/Results_of_imposters.optimize")) {
   dir.create("03_Output/Data/Results_of_imposters.optimize")
}

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


#Define the combinations of values for the three hyperparameters "distance", 
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

#Iterate through all rows of features.
#WARNING: Be aware that on an average household computer, this calculation can 
#easily take several days! If you want to get a preview of the results while
#the calculation is running, you can execute the R-Script "02-2_Preview Tuning
#Results.R" as local job: Go to the "Jobs" tab in the bottom left area of RStudio,
#click on "Start Local Job", then select the said R-Script, and check the box 
#"Run job with copy of global environment". Important: Under "Copy job results",
#leave the default "Don't copy" as it is. 
for (i in 1:nrow(features)) {
   
   #Make sure that imp.params contains no old values
   imp.params[1:nrow(imp.params), 4:ncol(imp.params)] = 0
   
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
   p1_vals[] = NA
   p2_vals[] = NA
   
   for (j in 1:nrow(imp.params)) { 
      for (k in 1:iterations) {
         imp.opt.res = imposters.optimize(
            reference.set = training.freq.table,
            parameter.incr = 0.05,
            distance = imp.params[j, "dist"],
            features = imp.params[j, "feat"],
            imposters = imp.params[j, "imp"]
         )
         
         #Break conditions: If the values are so bad that it is not worth going
         #through all iterations, then proceed with the next parameter combination.
         if(check_p1_p2_constraints(imp.opt.res) == FALSE) {
            break
         }
         
         #Write the values into the table of the results
         imp.params[j, 4 + (2 * k) - 2] = imp.opt.res[1]
         imp.params[j, 5 + (2 * k) - 2] = imp.opt.res[2]
         p1_vals[k] = imp.opt.res[1]
         p2_vals[k] = imp.opt.res[2]
         
      }
      #Add the means in the last two columns
      imp.params[j, "p1_avg"] = mean(p1_vals, na.rm = T)
      imp.params[j, "p2_avg"] = mean(p2_vals, na.rm = T)
      p1_vals[] = NA
      p2_vals[] = NA
   }
   
   #Create name of the file to be written
   filename02 = paste("03_Output/Data/Results_of_imposters.optimize/", 
                    "imposters.optimize-",
                    i,
                    "-",
                    paste(t(as.matrix(features[i,])), collapse = "-"), 
                    "-gram-",
                    format(Sys.time(), format = "%Y-%m-%d_%H-%M-%S"),
                    ".csv",
                    sep = "")
   
   #Create file header with some control information
   control.information = data.frame(
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
   #then the Delimiter "Semicolon".
   write.table(
      x = control.information,
      file = filename02,
      dec = ".",
      sep = ";",
      col.names = F,
      row.names = F
   )
   
   #Write the finished imp.params table into the file
   write.table(x = imp.params, 
             file = filename02,
             append = T,
             dec = ".",
             sep = ";",
             row.names = F)
   
}
