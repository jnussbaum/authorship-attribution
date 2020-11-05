# 04 STATISTICAL ANALYSIS OF THE IMPOSTERS' METHOD'S RESULTS

# In order to run this RScript, you need
# - either: the results of 03 ANALYSIS WITH THE IMPOSTERS' METHOD in your global 
#   environment 
# - or: the file "imposters.final.results.RData" from an earlier run of that script
#
# In the second case, you can now load the required files:
if (file.exists("03_Output/Data/Results_of_01_Preprocessing.RData")) {
  load(file = "03_Output/Data/Results_of_01_Preprocessing.RData")
}
if (file.exists("03_Output/Data/imposters.final.results.RData")) {
  load(file = "03_Output/Data/imposters.final.results.RData")
}

#Create a boxplot for each test text, giving an overview of the results of all
#feature-hyperparamter-combinations for the test text in question.
#The results are probabilities for every of the five author-candidates.

#Iterate through all test texts
for(testname04 in test.names) {
  
  filename04 = paste("03_Output/Plots/", testname04, ".png", sep = "")
  
  #Open a plot device with a width 90% of the height
  png(filename04, width = 450, height = 500)
  
  #The following plotting will be clipped to the plot region (innermost),
  #and the outer margins extend from 0/0.1 to 1/1 (cut off 90% of height)
  par(xpd = FALSE, omd = c(0, 1, 0.1, 1))
  
  #Plot one boxplot with five boxes, one per author-candidate
  boxplot.default(imposters.final.results[testname04, "John", ],
                  imposters.final.results[testname04, "Luke", ],
                  imposters.final.results[testname04, "Mark", ],
                  imposters.final.results[testname04, "Matthew", ],
                  imposters.final.results[testname04, "Paul", ],
                  names = candidates)
  
  #Set some labels
  title(main = testname04,      #main title on top
        ylab = "Probabilty",    #y-axis label
  )
  
  #Switch clipping to device region
  par(xpd = NA)
  
  #Add subtitle as text in the under margin
  mtext(text = paste(" \nOverview over the results of all",
                     nrow(good.params),
                     "feature-hyperparameter-combinations. \nEvery combination",
                     "resulted in one probability estimate per author-\ncandidate.",
                     "For every author-candidate, the box-plot visualises the",
                     "\ndistribution of the data points."
                     ),
        side = 1,          #bottom
        #line = 2,         #on which MARgin line, starting at 0 counting outwards.
        adj = 0,           #left adjustment
        outer = TRUE,      #use outer margins if available
        at = c(0.1, 0.1)   #x and y coordinates between [0,1]
  )
  
  dev.off()
}
