# 01 PREPROCESSING

# It is assumed that in the working directory, there are two folders named
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
# [A-Z]+                Mandatory: one or more capital letters (first group) at the beginning
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
require("stringi")
require("stylo")

#Set Working Directory
#for my Mac:
setwd(
  "/Users/nusjoh00/Desktop/Dropbox/Lehrveranstaltungen/20FS Lauer Machine Learning/Autorerkennung NT/authorship-attribution"
)
#for my Windows:
setwd(
  "C:/Users/Johannes/Dropbox/Lehrveranstaltungen/20FS Lauer Machine Learning/Autorerkennung NT/authorship-attribution"
)


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


#Prepare empty directories for the different text representations
training.path = paste(getwd(), "/Training_Data/", sep = "")
# if (!dir.exists("Training_Data/Greek")) {
#   dir.create("Training_Data/Greek")
# }
# if (!dir.exists("Training_Data/Strong")) {
#   dir.create("Training_Data/Strong")
# }
# if (!dir.exists("Training_Data/POS_L")) {
#   dir.create("Training_Data/POS_L")
# }
# if (!dir.exists("Training_Data/POS_S")) {
#   dir.create("Training_Data/POS_S")
# }

#Prepare unparsed, empty corpora (lists of class "stylo.corpus")
training.corpus.Greek = vector("list", length = length(training.names))
training.corpus.Strong = vector("list", length = length(training.names))
training.corpus.POS_L = vector("list", length = length(training.names))
training.corpus.POS_S = vector("list", length = length(training.names))

names(training.corpus.Greek) = training.names
names(training.corpus.Strong) = training.names
names(training.corpus.POS_L) = training.names
names(training.corpus.POS_S) = training.names

class(training.corpus.Greek) = "stylo.corpus"
class(training.corpus.Strong) = "stylo.corpus"
class(training.corpus.POS_L) = "stylo.corpus"
class(training.corpus.POS_S) = "stylo.corpus"


#Load one training file after the other, and extract different text representations
#from it. Then, save the representations in different files and add them to 
#the prepared corpora.
for (file_no in 1:length(training.names)) {
  
  training.file.path = paste(training.path, training.names[file_no], ".txt", sep = "")
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
  ##### BUG: IN MARK, TWO GREEK WORDS ARE MISSING
  
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
  
  #Write the representations into files
  # write(
  #   training.file.Greek,
  #   paste(training.path, "Greek/", training.names[file_no], ".txt", sep = ""),
  #   ncolumns = 1
  # )
  # 
  # write(
  #   training.file.Strong,
  #   paste(training.path, "Strong/", training.names[file_no], ".txt", sep = ""),
  #   ncolumns = 1
  # )
  # 
  # write(
  #   training.file.POS_L,
  #   paste(training.path, "POS_L/", training.names[file_no], ".txt", sep = ""),
  #   ncolumns = 1
  # )
  # 
  # write(
  #   training.file.POS_S,
  #   paste(training.path, "POS_S/", training.names[file_no], ".txt", sep = ""),
  #   ncolumns = 1
  # )
  
  #Write the representations into the stylo corpora
  training.corpus.Greek[file_no] = training.file.Greek
  training.corpus.Strong[file_no] = training.file.Strong
  training.corpus.POS_L[file_no] = training.file.POS_L
  training.corpus.POS_S[file_no] = training.file.POS_S
  
  #End of "Training" for-loop
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

#Prepare empty directories for the different text representations
test.path = paste(getwd(), "/Test_Data/", sep = "")
# if (!dir.exists("Test_Data/Greek")) {
#   dir.create("Test_Data/Greek")
# }
# if (!dir.exists("Test_Data/Strong")) {
#   dir.create("Test_Data/Strong")
# }
# if (!dir.exists("Test_Data/POS_L")) {
#   dir.create("Test_Data/POS_L")
# }
# if (!dir.exists("Test_Data/POS_S")) {
#   dir.create("Test_Data/POS_S")
# }

#Prepare unparsed, empty corpora (lists of class "stylo.corpus")
test.corpus.Greek = vector("list", length = length(test.names))
test.corpus.Strong = vector("list", length = length(test.names))
test.corpus.POS_L = vector("list", length = length(test.names))
test.corpus.POS_S = vector("list", length = length(test.names))

names(test.corpus.Greek) = test.names
names(test.corpus.Strong) = test.names
names(test.corpus.POS_L) = test.names
names(test.corpus.POS_S) = test.names

class(test.corpus.Greek) = "stylo.corpus"
class(test.corpus.Strong) = "stylo.corpus"
class(test.corpus.POS_L) = "stylo.corpus"
class(test.corpus.POS_S) = "stylo.corpus"

#Load one test file after the other, and extract different text representations
#from it. Then, save the representations in different files and add them to 
#the prepared corpora.
for (file_no in 1:length(test.names)) {
  
  test.file.path = paste(test.path, test.names[file_no], ".txt", sep = "")
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
  
  #Write the representations into files
  # write(test.file.Greek,
  #       paste(test.path, "Greek/", test.names[file_no], ".txt", sep = ""),
  #       ncolumns = 1)
  # 
  # write(test.file.Strong,
  #       paste(test.path, "Strong/", test.names[file_no], ".txt", sep = ""),
  #       ncolumns = 1)
  # 
  # write(test.file.POS_L,
  #       paste(test.path, "POS_L/", test.names[file_no], ".txt", sep = ""),
  #       ncolumns = 1)
  # 
  # write(test.file.POS_S,
  #       paste(test.path, "POS_S/", test.names[file_no], ".txt", sep = ""),
  #       ncolumns = 1)
  
  #Write the representations into the stylo corpora
  test.corpus.Greek[file_no] = test.file.Greek
  test.corpus.Strong[file_no] = test.file.Strong
  test.corpus.POS_L[file_no] = test.file.POS_L
  test.corpus.POS_S[file_no] = test.file.POS_S
  
  #End of "Test_Data" for-loop
}



#Save the results of this script
if (dir.exists("RData") == FALSE) {
  dir.create("RData")
}

save(list = ls(all.names = T),
     file = "RData/Results of 01_Preprocessing.RData",
     envir = .GlobalEnv)
