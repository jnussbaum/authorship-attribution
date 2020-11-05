# 01 PREPROCESSING

# In order to ensure that all file paths work, please *ALWAYS* open this project
# by opening "authorship-attribution.Rproj" first. 

# It is assumed that in the folder "01_Data", there are two folders named
# "Training_Data" and "Test_Data", with the slices from this file:
# https://github.com/getbible/Unbound-Biola/blob/master/Greek__NT_Westcott_Hort_
# UBS4_variants_Parsed__westcotthort__LTR.txt?raw=true

# First, the regexes used for preprocessing are explained:
# Credits: All regexes built and tested with https://regexr.com

# Regex to remove all "{VAR1: ... }" and "VAR2":
# [{]VAR1.+?[}])|VAR2
# Explanation:
# [{]VAR1.+?[}])  Match everything between {} which begins with "VAR1"
# |VAR2           Match only the letters "VAR2"

# Regex for Greek words:
# [\U1F00-\U1FBC\U1FC2-\U1FCC\U1FD0-\U1FDB\U1FE0-\U1FEC\U1FF2-\U1FFC]+

# Regex for POS tags:
# (?<= )(?!G)[A-Z]+(-[A-Z0-9]+){0,2}
# Explanation:
# (?<= )                Positive lookbehind: Match must be preceded by whitespace,
#                       in order to prevent matching a second part of a POS-Tag
# (?!G)                 Negative lookahead to prevent matching Strong numbers
# [A-Z]+                Mandatory: one or more capital letters (first group) at 
#                       the beginning
# (-[A-Z0-9]+){0,2}     0-2 times: a dash followed by letters or numbers

# Regex for first part only of POS tags:
# (?<= )(?!G)[A-Z]+

# Regex for Strong numbers:
# (?<![0-9] )G[0-9]{1,4}
# Explanation:
# (?<![0-9] )  Negative lookbehind: The second of two consecutive strong numbers
#              is discarded
# G[0-9]{1,4}  Capital letter G followed by 1-4 digits



# Load the necessary packages
if(require("stringi") == FALSE) {
  install.packages("stringi")
  library("stringi")
}
if(require("stylo") == FALSE) {
  install.packages("stylo")
  library("stylo")
}

#Set the names of the training texts
training.names = c(
  "John_1John",
  "John_2John",
  "John_3John",
  "John_John",
  "John_Revelation",
  "Luke_Acts",
  "Luke_Luke",
  "Mark_Mark1-8",
  "Mark_Mark9-16,8",
  "Matthew_Matthew1-14",
  "Matthew_Matthew15-28",
  "Paul_Romans",
  "Paul_1Corinthians",
  "Paul_2Corinthians",
  "Paul_Galatians",
  "Paul_Philippians",
  "Paul_1Thessalonians",
  "Paul_Philemon"
)

candidates = c("John", "Luke", "Mark", "Matthew", "Paul")

#Prepare unparsed, empty corpora (lists of class "stylo.corpus")
training.corpus.Greek = vector(mode = "list", length = length(training.names))
training.corpus.Strong = vector(mode = "list", length = length(training.names))
training.corpus.POS_L = vector(mode = "list", length = length(training.names))
training.corpus.POS_S = vector(mode = "list", length = length(training.names))

names(training.corpus.Greek) = training.names
names(training.corpus.Strong) = training.names
names(training.corpus.POS_L) = training.names
names(training.corpus.POS_S) = training.names

class(training.corpus.Greek) = "stylo.corpus"
class(training.corpus.Strong) = "stylo.corpus"
class(training.corpus.POS_L) = "stylo.corpus"
class(training.corpus.POS_S) = "stylo.corpus"

#Load one training file after the other, and extract different text representations
#from it. Then, add the representations to the prepared corpora.
for (file_no in 1:length(training.names)) {
  
  training.file.path = paste("01_Data/Training_Data/", 
                             training.names[file_no], 
                             ".txt", 
                             sep = "")
  training.file = readLines(training.file.path, n = -1L, encoding = "UTF-8")
  
  #Remove all "{VAR1: ... }" and "VAR2"
  training.file = stri_replace_all_regex(str = training.file,
                                         pattern = "([{]VAR1.+?[}])|VAR2",
                                         replacement = "")
  
  #Extract the different text representations
  training.file.Greek = paste(unlist(
    stri_extract_all_regex(
      str = training.file,
      pattern = "[\u0370-\u03ff\u1F00-\u1FBC\u1FC2-\u1FCC\u1FD0-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FFC]+",
      simplify = FALSE,
      encoding = "UTF-8"
    )
  ), collapse = " ")

  training.file.Strong = paste(unlist(
    stri_extract_all_regex(
      str = training.file,
      pattern = "(?<![0-9] )G[0-9]{1,4}",
      simplify = FALSE
    )
  ), collapse = " ")

  training.file.POS_L = paste(unlist(
    stri_extract_all_regex(
      str = training.file,
      pattern = "(?<= )(?!G)[A-Z]+(-[A-Z0-9]+){0,2}",
      simplify = FALSE
    )
  ), collapse = " ")

  training.file.POS_S = paste(unlist(
    stri_extract_all_regex(
      str = training.file,
      pattern = "(?<= )(?!G)[A-Z]+",
      simplify = FALSE
    )
  ), collapse = " ")
  
  #Write the representations into the stylo corpora
  training.corpus.Greek[file_no] = training.file.Greek
  training.corpus.Strong[file_no] = training.file.Strong
  training.corpus.POS_L[file_no] = training.file.POS_L
  training.corpus.POS_S[file_no] = training.file.POS_S
  
}






#Set the names of the test texts
test.names = c(
  "Ephesians",
  "Colossians",
  "2Thessalonians",
  "1Timothy",
  "2Timothy",
  "Titus",
  "Hebrews",
  "Mark16_9-20",
  "John7_53-8_11",
  "Romans16_25-27"
)

#Prepare unparsed, empty corpora (lists of class "stylo.corpus")
test.corpus.Greek = vector(mode = "list", length = length(test.names))
test.corpus.Strong = vector(mode = "list", length = length(test.names))
test.corpus.POS_L = vector(mode = "list", length = length(test.names))
test.corpus.POS_S = vector(mode = "list", length = length(test.names))

names(test.corpus.Greek) = test.names
names(test.corpus.Strong) = test.names
names(test.corpus.POS_L) = test.names
names(test.corpus.POS_S) = test.names

class(test.corpus.Greek) = "stylo.corpus"
class(test.corpus.Strong) = "stylo.corpus"
class(test.corpus.POS_L) = "stylo.corpus"
class(test.corpus.POS_S) = "stylo.corpus"

#Load one test file after the other, and extract different text representations
#from it. Then, add the representations to the prepared corpora.
for (file_no in 1:length(test.names)) {
  
  test.file.path = paste("01_Data/Test_Data/", 
                         test.names[file_no], 
                         ".txt", 
                         sep = "")
  test.file = readLines(test.file.path, n = -1L, encoding = "UTF-8")
  
  #Remove all "{VAR1: ... }" and "VAR2"
  test.file = stri_replace_all_regex(str = test.file,
                                     pattern = "([{]VAR1.+?[}])|VAR2",
                                     replacement = "")
  
  #Extract the different text representations
  test.file.Greek = paste(unlist(
    stri_extract_all_regex(
      str = test.file,
      pattern = "[\u0370-\u03ff\u1F00-\u1FBC\u1FC2-\u1FCC\u1FD0-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FFC]+",
      simplify = FALSE,
      encoding = "UTF-8"
    )
  ), collapse = " ")
  
  test.file.Strong = paste(unlist(
    stri_extract_all_regex(
      str = test.file,
      pattern = "(?<![0-9] )G[0-9]{1,4}",
      simplify = FALSE
    )
  ), collapse = " ")

  test.file.POS_L = paste(unlist(
    stri_extract_all_regex(
      str = test.file,
      pattern = "(?<= )(?!G)[A-Z]+(-[A-Z0-9]+){0,2}",
      simplify = FALSE
    )
  ), collapse = " ")

  test.file.POS_S = paste(unlist(
    stri_extract_all_regex(
      str = test.file,
      pattern = "(?<= )(?!G[0-9])[A-Z]+",
      simplify = FALSE
    )
  ), collapse = " ")
  
  #Write the representations into the stylo corpora
  test.corpus.Greek[file_no] = test.file.Greek
  test.corpus.Strong[file_no] = test.file.Strong
  test.corpus.POS_L[file_no] = test.file.POS_L
  test.corpus.POS_S[file_no] = test.file.POS_S

}



#Save the results of this script
save(list = ls(all.names = T),
     file = "03_Output/Data/Results_of_01_Preprocessing.RData",
     envir = .GlobalEnv)
