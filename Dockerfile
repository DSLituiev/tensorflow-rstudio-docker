
# parts from dceoy/rstudio-server

FROM tensorflow/tensorflow:latest-gpu-py3

ENV DEBIAN_FRONTEND noninteractive
ENV CRAN_URL https://cloud.r-project.org/

ADD https://s3.amazonaws.com/rstudio-server/current.ver /tmp/ver
RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        apt-transport-https apt-utils ca-certificates gnupg \
      && echo "deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/" \
        > /etc/apt/sources.list.d/r.list \
      && apt-key adv --keyserver keyserver.ubuntu.com \
         --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        curl libapparmor1 libclang-dev libedit2 libssl1.0.0 lsb-release \
        psmisc r-base sudo \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -vrf /var/lib/apt/lists/* \
      && apt-get update

RUN apt-get install -y gdebi-core \
    && curl -O https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb \
    && gdebi -n rstudio-server-1.1.453-amd64.deb

RUN set -e \
      && useradd -m -d /home/rstudio -g rstudio-server rstudio \
      && echo rstudio:rstudio | chpasswd \
      && echo "r-cran-repos=${CRAN_URL}" >> /etc/rstudio/rsession.conf

RUN chmod 777 -R /home/rstudio/ \
    && chmod 777 -R /usr/local/lib/python3.5/dist-packages/

RUN pip install keras 
# &&  apt-get install python-virtualenv
RUN R -e "install.packages(c('tidyr', 'ggplot2', 'reticulate'));"
RUN R -e "library(reticulate); \
	  install.packages('tensorflow'); \
          library(tensorflow); \
	  use_python('/usr/local/bin/python'); \
	  install.packages('keras')";

RUN echo "library(reticulate); use_python('/usr/local/bin/python')" > ~/.Rprofile
EXPOSE 8787


ENTRYPOINT ["/usr/lib/rstudio-server/bin/rserver"]
CMD ["--server-daemonize=0", "--server-app-armor-enabled=0"]

