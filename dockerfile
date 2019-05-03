FROM trestletech/plumber
# Install r packages
RUN /usr/bin/Rscript -e "install.packages(c('shiny', 'shinyWidgets', 'shinydashboard', 'DT', 'data.table', 'reshape2', 'purrr', 'reticulate', 'ROCR', 'ggplot2'), dependencies = TRUE)"
RUN apt-get update
# install Python!
RUN apt-get install -y python python-pip
RUN pip install --upgrade pip
RUN pip install --upgrade tensorflow keras  --ignore-installed six
RUN mkdir -p /usr/SPOC
VOLUME /usr/SPOC/
#ADD SPOC /usr/SPOC/