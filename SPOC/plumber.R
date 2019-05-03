# plumber.R
setwd('/usr/SPOC/')

# Load necessary libraries, local source code, and in-memory objects
library(data.table)
source('interactive.R')
pocs.dt <- LoadPOCLkp()

#* Retreives a list of applicable PO&C codes for given text, sorted descending 
#* by probability of applicability
#* @param text Text to get PO&Cs for
#* @param pocDescriptions Whether or not to return the PO&C descriptions
#* @param probabilities Whether or not to return the probabilities
#* @param topN Only return the topN PO&Cs with the highest probabilities
#* @param probabilityThreshold Only return PO&Cs with probabilities above the 
#*        threshold
#* @post /pocs
function(text, 
         pocDescriptions=T, 
         probabilities=T, 
         topN=Inf, 
         probabilityThreshold=0.0){
  # get PO&C predictions
  res <- PredictPOCs(text) 
  # Build a data.table
  res.dt <- data.table(POC = names(res), PROBABILITY = unname(res)) 
  # Merge in the PO&C descriptions
  res.dt <- merge(res.dt, pocs.dt, by = 'POC', all.x = T)
  # Sort by probability descending
  res.dt <- res.dt[order(-res.dt$PROBABILITY)] 
  # Only select applicable columns
  res.dt <- res.dt[,c("POC", "DESCRIPTION", "PROBABILITY")] 
  # Filter to topN or fewer records
  topN <- min(nrow(res.dt), topN) 
  res.dt <- res.dt[1:topN,]
  # Filter any records below the probability threshold
  res.dt <- res.dt[res.dt$PROBABILITY >= probabilityThreshold, ] 
  # remove the DESCRIPTION column if pocDescriptions is not TRUE
  if(!pocDescriptions){ 
    res.dt[, DESCRIPTION:=NULL]
  }
  # remove the Probabilities column if probabilities is not TRUE
  if(!probabilities){ 
    res.dt[, PROBABILITY:=NULL]
  }
  return(res.dt)
}
