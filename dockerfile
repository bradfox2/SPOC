FROM trestletech/plumber
# Install r packages
RUN /usr/bin/Rscript -e "install.packages(c('shiny', 'shinyWidgets', 'shinydashboard', 'DT', 'data.table', 'reshape2', 'purrr', 'reticulate', 'ROCR', 'ggplot2'), dependencies = TRUE)"
RUN echo 'deb http://deb.debian.org/debian bullseye main' > /etc/apt/sources.list
RUN apt-get update
# install Python!
RUN apt-get install -y python python-pip
RUN pip install --upgrade pip
COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
RUN mkdir -p /usr/SPOC
VOLUME /usr/SPOC/
#ADD SPOC /usr/SPOC/
