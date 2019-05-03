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




#' File containing functions for saving and loading local data

library(data.table)

#' Deletes all site-specific data
ClearAllInfo <- function(){
  lapply(list.files('data/crs/', full.names = T), file.remove)
  lapply(list.files('data/pocs/', full.names = T), file.remove)
  return(NULL)
}

#' Stores CRs and their text for a given site
StoreCRInfo <- function(dateVec, siteVec, siteUidVec, textVec){
  newCRs <- data.table(DATE = dateVec, SITE = siteVec, SITEUID = siteUidVec, TEXT = textVec)
  saveRDS(newCRs, paste0('data/crs/', runif(1), '.RDS'))
}

#' Loads the CRs into memory
LoadCRInfo <- function(){
  listOStuff <- lapply(list.files('data/crs/',full.names = T), readRDS)
  return(do.call('rbind', listOStuff))
}

#' Stores CRs PO&Cs locally
StoreCRPOCs <- function(siteVec, siteUidVec, pocVec){
  pocs <- data.table(SITE = siteVec, SITEUID = siteUidVec, POC = pocVec)
  saveRDS(pocs, paste0('data/pocs/', runif(1), '.RDS'))
}

#' Loads the CRs PO&Cs into memory
LoadCRPOCS <- function(){
  listOStuff <- lapply(list.files('data/pocs/',full.names = T), readRDS)
  return(do.call('rbind', listOStuff))
}

#' Stores a vector for decoding the model outputs
StorePOCDecoder <- function(pocdecoder){
  saveRDS(pocdecoder, file = 'data/pocdecoder.RDS')
}

#' Retrieves the decoder
LoadPOCDecoder <- function(pocdecoder){
  return(readRDS('data/pocdecoder.RDS'))
}

#' Stores a PO&C Details lookup table
StorePOCLkp <- function(poclkp.dt){
  saveRDS(poclkp.dt, file = 'data/poclkp.RDS')
}

#' Loads the PO&C Details lookup table into memory
LoadPOCLkp <- function(){
  return(readRDS('data/poclkp.RDS'))
}