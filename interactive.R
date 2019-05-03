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

#' Contains functions and global variables for interacting with the PO&C models

library(reshape2)
library(purrr)
library(reticulate)
library(data.table)

np <- import('numpy')
keras <- import('keras')
pickle <- import('pickle')

source('industry_helper_functions.R')

# load models and supporting data
load(file = "data/model/model.json")
model<-keras$models$model_from_json(json_string = json)
model$load_weights(filepath = "data/model/model_incremental.model")
load(file = "data/model/ktt.pkl")
ktt <- pickle$loads(ktts)
pocdecoder <- LoadPOCDecoder()

#' Helper function for preparing data for model
#' This is needed for any text vectors of a single value, due to inconsistent
#' ways that single length vectors are converted to python data via reticulate
padSingleLengthVecs <- function(textSeq){
  for(i in 1:length(textSeq)){
    if(length(textSeq[[i]])== 1){
      textSeq[[i]] <- c(textSeq[[i]],0)
    }
  }
  return(textSeq)
}

#' Prepares text data to be input into the PO&C model
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

#' Given a single text value, provide the most likely PO&Cs
PredictPOCs <- function(text, incremental = F){
  options(warn=-1)
  testtt.dt <- data.table(SITEUID = c('A','B'), 
                          CRTEXT = c(text, 'test'))
  text2 <- prepChrData(c("CRTEXT"),
                       testtt.dt,
                       "SITEUID",
                       ktt,
                       model = model)
  pred2 <- model$predict(text2$CRTEXT)
  colnames(pred2) <- pocdecoder#names(pocs.dt)[3:ncol(pocs.dt)]
  options(warn=0)
  return(sort(pred2[1, ], decreasing = T))
}

