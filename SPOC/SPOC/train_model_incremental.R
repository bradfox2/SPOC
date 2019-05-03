#Copyright (C) Arizona Public Service - All Rights Reserved 
#
#Any referenced libraries utilized within are licensed per original author. 
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
#Unauthorized copying of this file, via any medium is strictly prohibited
#Proprietary and confidential
#
#Written by Jerrold Vincent <jerrold.vincent@aps.com> and Bradley Fox
#<bradley.fox@aps.com> September 2018

#' Script used for training a model from scratch

library(purrr)
library(reticulate)
library(ROCR)
library(reshape2)
library(ggplot2)
source('industry_helper_functions.R')

np <- import('numpy')
keras <- import('keras')
pickle <- import('pickle')

# load existing model and supporting data
load(file = "data/model/model.json")
model<-keras$models$model_from_json(json_string = json)
model$load_weights(filepath = "data/model/model.model")
model$compile(optimizer = 'adam', loss = 'categorical_crossentropy')

load(file = "data/model/ktt.pkl")
ktt <- pickle$loads(ktts)
pocdecoder <- LoadPOCDecoder()


### load data for initial model training and initial tokenizer training
crs.dt <- LoadCRInfo()
pocs.dt <- LoadCRPOCS()
crs.dt <- crs.dt[order(crs.dt$SITE, crs.dt$SITEUID)]
pocs.dt <- merge(crs.dt, pocs.dt, by = c("SITE", "SITEUID"), all.x = T)
pocs.dt$CT <- 1
pocs.dt <- dcast.data.table(
  pocs.dt, 
  formula = SITE + SITEUID ~ POC, 
  fun.aggregate = max, 
  value.var = "CT", 
  fill = 0)

missingNames <- names(pocs.dt)[3:ncol(pocs.dt)]
missingNames <- missingNames[!(missingNames %in% pocdecoder)]
for(mn in missingNames){
  print(paste0("PO&C Code \'", mn, "' not found in model"))
}

# Fills in columns where PO&C codes don't exist
for(poc in pocdecoder[!(pocdecoder %in% names(pocs.dt))]){
  pocs.dt[,(poc) := 0.0]
}

pocs.dt <- pocs.dt[order(pocs.dt$SITE, pocs.dt$SITEUID)]
# Orders and trims dataset
pocs.dt <- pocs.dt[, c("SITE", "SITEUID", pocdecoder), with=FALSE]

padSingleLengthVecs <- function(textSeq){
  for(i in 1:length(textSeq)){
    #print(i)
    if(length(textSeq[[i]])== 1){
      #print(textSeq[[i]])
      #print(class(textSeq[[i]]))
      #print(i)
      textSeq[[i]] <- c(textSeq[[i]],0)
    }
  }
  return(textSeq)
}

prepChrData <- function(srcTextVars, src, key, kerasTextTokenizer, model = NA){
  preppedData<-map(srcTextVars, function(x){
    txt <- src[[x]]
    if(length(txt) == 1) txt <- list(txt)
    textSeq <- kerasTextTokenizer$texts_to_sequences(txt)
    textSeq <- padSingleLengthVecs(textSeq)
    if(!is.na(model)){ #inference 
      l<-model$get_layer(name = x)
      maxLen <- l$input_shape[[2]]
      textSeqPadded<-keras$preprocessing$sequence$pad_sequences(sequences = textSeq, maxlen = maxLen)
    }else{ #training
      textSeqPadded<-keras$preprocessing$sequence$pad_sequences(sequences = textSeq)
    }
    rownames(textSeqPadded) <- src[[key]] 
    return(textSeqPadded)
  })
  names(preppedData) <- srcTextVars
  return(preppedData)
}


text <- prepChrData(c("TEXT"),
                    crs.dt,
                    "SITEUID",
                    ktt)

trn <- sample(1:nrow(pocs.dt), nrow(pocs.dt)*.8)
trn <- (1:nrow(pocs.dt)) %in% trn
tst <- !trn

for(i in 1:1){
  model$fit(
    text$TEXT[trn,],
    as.matrix(pocs.dt[,3:ncol(pocs.dt)])[trn,],
    validation_split = .05,
    shuffle = T
  )
  
  preds <- model$predict(text$TEXT[tst,])
  pred <- prediction(as.vector(preds), as.vector(as.matrix(pocs.dt[,3:ncol(pocs.dt)][tst,])))#pocTgt[tstL,]))
  perf <- performance(pred,"auc") 
  auc <- perf@y.values[[1]]
  print(auc)
  #plot(perf)
}

#save incrementally updated weights
model$save_weights(filepath = "data/model/model_incremental.model")
