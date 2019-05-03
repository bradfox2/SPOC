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

pocs.dt <- pocs.dt[order(pocs.dt$SITE, pocs.dt$SITEUID)]

trainTokenizer <- function(srcTextVars, src, kerasTextTokenizer){
  preppedData<-map(srcTextVars, function(x){
    kerasTextTokenizer$fit_on_texts(src[[x]])
    kerasTextTokenizer$num_words = 10000L
    return()
  })
  return(kerasTextTokenizer)
}

#Create the Keras CNN LSTM text processing layers, with the layer
#details from texttokenizer and dataSet
chrLSTMCNNLayer <- function(textTokenizer, dataSet, name = NA){
  max_features = as.integer(textTokenizer$num_words+1)
  print(max_features)
  print(dim(dataSet))
  max_length = dim(dataSet)[2]
  print(max_length)
  embedding_size = 512L
  # Convolution
  kernel_size = 5L #look at sequences of 5 words
  filters = 64L
  pool_size = 4L
  
  # LSTM
  lstm_output_size = 128L
  
  # Training
  batch_size = 30L
  epochs = 2L
  input <- keras$layers$Input(shape = list(max_length), name = name)
  embed <- py_call(keras$layers$Embedding(max_features, embedding_size, input_length = max_length), input)
  layer1 <- py_call(keras$layers$Dropout(0.25), embed)
  conv1 <- py_call(keras$layers$Conv1D(filters,
                                       kernel_size,
                                       padding='valid',
                                       activation='relu',
                                       strides=1L), layer1)
  pool1 <- py_call(keras$layers$MaxPooling1D(pool_size=pool_size), conv1)
  lstm1 <- py_call(keras$layers$GRU(lstm_output_size), pool1)
  return(c(input,lstm1))
}

#function to ensure any single length vectors are padded to at least length 2
#so that keras text tokenizer doesnt get mad
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

#function to tokenize the text and construct sequences of tokens into something that
#the NN can utilize
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

#clear tensorflow session and instatiate new keras text tokenizer object
keras$backend$clear_session()
ktt <- keras$preprocessing$text$Tokenizer(num_words = 10000L)

#train tokenizer on dictionaries
ktt <- trainTokenizer(c("TEXT"),
                      crs.dt,
                      ktt)

ktt$num_words <- 10000L

text <- prepChrData(c("TEXT"),
                    crs.dt,
                    "SITEUID",
                    ktt)

dropoutRate <- .2
crTextLayer <- chrLSTMCNNLayer(ktt, text$TEXT, 'CRTEXT')
finalmodel.m <- py_call(keras$layers$Dropout(dropoutRate), crTextLayer[[2]])
finalmodel.m <- py_call(keras$layers$Dense(200L, activation = "relu"), finalmodel.m)
finalmodel.m <- py_call(keras$layers$Dropout(dropoutRate), finalmodel.m)
finalmodel.m <- py_call(keras$layers$Dense(200L, activation = "relu"), finalmodel.m)
finalmodel.m <- py_call(keras$layers$Dropout(dropoutRate), finalmodel.m)
finalmodel.m <- py_call(keras$layers$Dense(as.integer(ncol(pocs.dt)-2), activation = "sigmoid"), finalmodel.m)

model <- keras$models$Model(inputs = crTextLayer[[1]], outputs = finalmodel.m)

model$compile(optimizer = 'adam', loss = 'categorical_crossentropy')
model$summary()

trn <- sample(1:nrow(pocs.dt), nrow(pocs.dt)*.8)
trn <- (1:nrow(pocs.dt)) %in% trn
tst <- !trn

#model training loop, fit model to a [trn] sampled dataset
for(i in 1:3){
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

#save model and ktt
json<-model$to_json()
save(json,file = "data/model/model.json")
model$save_weights(filepath = "data/model/model.model")
model$save_weights(filepath = "data/model/model_incremental.model")

ktts <- pickle$dumps(ktt)
save(ktts, file = 'data/model/ktt.pkl')

StorePOCDecoder(names(pocs.dt)[3:ncol(pocs.dt)])
#save(pocs.dt, file = 'data/model/pocs.RData')
