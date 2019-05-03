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

#prep packages
require(shiny)
require(shinyWidgets)
require(shinydashboard)
require(DT)
require(data.table)

setwd('../')
source('interactive.R')
pocs.dt <- LoadPOCLkp()

server <- function(input, output, session) {
  
  pocResults <- debounce(r = reactive({
    print("running search")
    return(PredictPOCs(input$query))
  }), millis = 1000)
  
  output$resultsTable <- renderDataTable({
    res <- pocResults()[1:200]
    res.dt <- data.table(POC = names(res), Probability = 100*unname(res))
    res.dt <- merge(res.dt, pocs.dt, by = 'POC', all.x = T)
    res.dt <- res.dt[order(-res.dt$Probability)]
    res.dt <- res.dt[,c("POC", "DESCRIPTION", "Probability")]
    res.dt$Probability <- paste0(sprintf('%.1f', res.dt$Probability), '%')
    return(datatable(res.dt))
  })
}