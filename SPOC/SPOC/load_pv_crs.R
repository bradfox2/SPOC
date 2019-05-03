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
# Example provided for how Palo Verde loads in their CR data                   #
################################################################################

library(data.table)
library(ROracle)

source('industry_helper_functions.R')

ClearAllInfo()

DBConnection <- function(envVar){
  library(ROracle)
  connStr <- Sys.getenv(envVar)
  connVars <- strsplit(connStr, '\\|')[[1]]
  drv <- DBI::dbDriver('Oracle')
  return(ROracle::dbConnect(drv, connVars[2], connVars[3], connVars[1]))
}

dbcon <- DBConnection('POC_CONNECT_STRING')

cr.sql <- "SELECT PVDW.FACT_CR_DETAILS.CR_CD,
      DIM_CR_IDNTFD_DT.DISPLAY_DT,
    DIM_CR_WRK_DESCR.PRBLEM_DESCR AS TEXT1,
    DIM_CR_WRK_DESCR.WRK_DESCR AS TEXT2,
        (SELECT MIN(WAT.ACTION_TAKEN_TEXT)
    FROM NIMS.WMECH_ACTIONS_TAKEN WAT
    JOIN NIMS.WORK_MECHANISMS WM
    ON WAT.WMECH_DB_ID                        = WM.DB_ID
    WHERE WM.WMTYPE_CODE                      = 'CR'
    AND ABS(WM.CREATE_DATE - WAT.CREATE_DATE) < (1/60/24)
    AND WM.DB_ID                              = PVDW.FACT_CR_DETAILS.CR_ID
    ) AS TEXT3,
    (SELECT MIN(WFT.COMMENT_TEXT)
    FROM NIMS.WMECH_FREEFORM_TEXTS WFT
    JOIN NIMS.WORK_MECHANISMS WM
    ON WFT.WMECH_DB_ID   = WM.DB_ID
    WHERE WM.WMTYPE_CODE = 'CR'
    AND FFTT_CODE        = 'IDEN_DISP'
    AND WM.DB_ID         = PVDW.FACT_CR_DETAILS.CR_ID
    ) AS TEXT4
    FROM PVDW.DIM_WORK_DESCRIPTION DIM_CR_WRK_DESCR,
    PVDW.DIM_WORK_TYPE DIM_CR_WRK_TYPE,
    PVDW.DIM_DATE DIM_CR_IDNTFD_DT,
    PVDW.FACT_CR_DETAILS
    WHERE ( PVDW.FACT_CR_DETAILS.CR_WRK_TYPE_SK =DIM_CR_WRK_TYPE.WRK_TYPE_SK )
    AND ( PVDW.FACT_CR_DETAILS.CR_WRK_DESCR_SK  =DIM_CR_WRK_DESCR.WRK_DESCR_SK )
    AND ( PVDW.FACT_CR_DETAILS.CR_IDNTFD_DT_SK  =DIM_CR_IDNTFD_DT.DATE_SK )
    AND DIM_CR_IDNTFD_DT.DISPLAY_DT            >= TO_DATE('01-07-2015','DD-MM-YYYY')
    AND DIM_CR_WRK_TYPE.WRK_WRKFLOW_STEP        > 170"

cr.dt <- data.table(ROracle::dbGetQuery(dbcon, cr.sql))
StoreCRInfo(dateVec = cr.dt$DISPLAY_DT, 
            siteVec = 'PALO VERDE', 
            siteUidVec = cr.dt$CR_CD, 
            textVec = paste(cr.dt$TEXT1, cr.dt$TEXT2, cr.dt$TEXT3, cr.dt$TEXT4, sep = '||'))

poc.sql <- "SELECT FCPC.CR_CD,
  DPC.PERFRMNC_OBJCTV_CRIT_CMBND
FROM PVDW.FACT_CR_POC_CODES FCPC
JOIN PVDW.DIM_POC_CODE DPC
ON FCPC.POC_CD_SK = DPC.POC_CD_SK"

poc.dt <- data.table(ROracle::dbGetQuery(dbcon, poc.sql))
StoreCRPOCs(siteVec = 'PALO VERDE',
            siteUidVec = poc.dt$CR_CD,
            pocVec = poc.dt$PERFRMNC_OBJCTV_CRIT_CMBND)

poclkp.dt <- data.table(ROracle::dbGetQuery(dbcon, 'select PERFRMNC_OBJCTV_CRIT_CMBND as POC, crit_descr as Description from pvdw.dim_poc_code'))
StorePOCLkp(poclkp.dt)

ROracle::dbDisconnect(dbcon)
