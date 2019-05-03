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

################################################################################
# Example provided for how to load data from csv into the tool                 #
################################################################################

################################################################################
# Put 3 csv files in the data/load/ folder in the following format
#   - crs.csv
#           "DISPLAY_DT","SITE","CR_ID","TEXT"
#           "2019-01-01","OPG","19-00001","example text 1 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00002","example text 2 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00003","example text 3 is an example of example text that is going to be used to test the system"
#           "2019-01-03","OPG","19-00004","example text 4 is an example of example text that is going to be used to test the system"
#           "2019-01-01","OPG","19-00005","example text 1 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00006","example text 2 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00007","example text 3 is an example of example text that is going to be used to test the system"
#           "2019-01-03","OPG","19-00008","example text 4 is an example of example text that is going to be used to test the system"
#           "2019-01-01","OPG","19-00009","example text 1 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00010","example text 2 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00011","example text 3 is an example of example text that is going to be used to test the system"
#           "2019-01-03","OPG","19-00012","example text 4 is an example of example text that is going to be used to test the system"
#           "2019-01-01","OPG","19-00013","example text 1 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00014","example text 2 is an example of example text that is going to be used to test the system"
#           "2019-01-02","OPG","19-00015","example text 3 is an example of example text that is going to be used to test the system"
#           "2019-01-03","OPG","19-00016","example text 4 is an example of example text that is going to be used to test the system"
#
#   - pocs.csv
#           "SITE","CR_ID","POC_CODE"
#           "OPG","19-00001","POC1"
#           "OPG","19-00001","POC2"
#           "OPG","19-00002","POC1"
#           "OPG","19-00002","POC3"
#           "OPG","19-00003","POC1"
#           "OPG","19-00003","POC2"
#           "OPG","19-00004","POC1"
#           "OPG","19-00004","POC3"
#           "OPG","19-00005","POC1"
#           "OPG","19-00005","POC2"
#           "OPG","19-00006","POC1"
#           "OPG","19-00006","POC3"
#           "OPG","19-00007","POC1"
#           "OPG","19-00007","POC2"
#           "OPG","19-00008","POC1"
#           "OPG","19-00008","POC3"
#           "OPG","19-00009","POC1"
#           "OPG","19-00009","POC3"
#           "OPG","19-00010","POC1"
#           "OPG","19-00010","POC2"
#           "OPG","19-00011","POC1"
#           "OPG","19-00011","POC2"
#           "OPG","19-00012","POC1"
#           "OPG","19-00012","POC3"
#           "OPG","19-00013","POC1"
#           "OPG","19-00013","POC2"
#           "OPG","19-00014","POC1"
#           "OPG","19-00014","POC3"
#           "OPG","19-00015","POC1"
#           "OPG","19-00015","POC2"
#           "OPG","19-00016","POC1"
#           "OPG","19-00016","POC3"
#
#   - pocdecoder.csv
#           "POC_CODE","DESCR"
#           "POC1","POC 1 description"
#           "POC2","POC 1 description"
#           "POC3","POC 1 description" 
################################################################################

source('industry_helper_functions.R')
library(data.table)

ClearAllInfo()

crs.df <- read.csv("data/load/crs.csv")
pocs.df <- read.csv("data/load/pocs.csv")
pocdecoder.dt <- as.data.table(read.csv("data/load/pocdecoder.csv"))

# convert date format
crs.df$DISPLAY_DT <- as.Date(crs.df$DISPLAY_DT, "%Y-%m-%d")

# store data locally
StoreCRInfo(dateVec = crs.df$DISPLAY_DT,
            siteVec = crs.df$SITE, 
            siteUidVec = crs.df$CR_ID, 
            textVec = crs.df$TEXT)

StoreCRPOCs(siteVec = pocs.df$SITE,
            siteUidVec = pocs.df$CR_ID,
            pocVec = pocs.df$POC_CODE)

StorePOCLkp(pocdecoder.dt)
