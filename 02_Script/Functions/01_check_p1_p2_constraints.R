#Since the calculation of p1 and p2 is very costly, it is highly recommended to
#define constraints. These constraints serve two purposes: Firstly, they are break
#conditions for the grid search. If a certain feature-hyperparameter-combination
#produces p1 and p2 values which don't meed the constraints, the remaining iterations
#aren't calculated. Secondly, before running the imposters method, the p1 and p2
#values are checked again if they meed the criteria. (This second check is necessary
#because in the history of this project, there were no break conditions in the beginning,
#and thus some data rows with very bad p1 and p2 values were calculated.)

check_p1_p2_constraints = function(input) {
   
   #Define the constraints
   max_p2 = 0.75
   max_diff = 0.3
   max_avg_diff = 0.2
   
   #Check if the input is a numeric vector of length 2 ...
   if ("numeric" == class(input)  &&  2 == length(input)) {
      
      #Check if values are legal
      if(!(all(0 <= input) && all(input <= 1) && input[1] <= input[2])) {
         stop(simpleError("Illegal values passed to 'check_p1_p2_constraints()'"))
      }
      
      #Check the defined constraints
      if (input[2] < max_p2  &&  input[2] - input[1] < max_diff) {
         return(TRUE)
      } else {
         return(FALSE)
      }
      
      
   # ... or a data.frame with named columns ...
   } else if ("data.frame" == class(input)) {
      
      all_p1 = grepl(pattern = "p1\U002E[0-9]{1,}", x = colnames(input))
      all_p2 = grepl(pattern = "p2\U002E[0-9]{1,}", x = colnames(input))
      
      #Check if values are legal
      if(!(all(0 <= input[all_p1]) && all(input[all_p1] <= 1) &&
           all(0 <= input[all_p2]) && all(input[all_p2] <= 1) &&
           all(input[all_p1] <= input[all_p2]))
         ) {
         stop(simpleError("Illegal values passed to 'check_p1_p2_constraints()'"))
      }
      
      #Check the defined constraints
      if (input["p1.1"] != 0
          && all(input[all_p2] < max_p2)
          && all(input[all_p2] - input[all_p1] < max_diff)
          && input["p2_avg"] - input["p1_avg"] < max_avg_diff
      ) {
         return(TRUE)
      } else {
         return(FALSE)
      }
      
   # ... or if the input is of an illegal class   
   } else {
      stop(simpleError(paste("Function 'check_p1_p2_constraints()' was called with", 
                             " an illegal parameter of class",
                             class(input),
                             "and length",
                             length(input)
                             )
                       )
           )
   }
}
