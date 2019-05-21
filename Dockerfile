
# parts from dceoy/rstudio-server
FROM ufoym/deepo:keras-py36-cu100
#FROM tensorflow/tensorflow:latest-gpu-py3

ENV DEBIAN_FRONTEND noninteractive
ENV CRAN_URL https://cloud.r-project.org/

ADD https://s3.amazonaws.com/rstudio-server/current.ver /tmp/ver
RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        apt-transport-https apt-utils ca-certificates gnupg \
      && echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" \
        > /etc/apt/sources.list.d/r.list \
      && apt-key adv --keyserver keyserver.ubuntu.com \
         --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        curl libapparmor1 libclang-dev libedit2 libssl1.0.0 lsb-release \
        psmisc r-base-core r-recommended r-base sudo \
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

RUN PYTHONPATH=$(pip show numpy | grep Location | cut -d' ' -f2) \
    && echo -e "PYTHONPATH:\t${PYTHONPATH}" \
    && chmod 777 -R /home/rstudio/ \
    && chmod 777 -R $PYTHONPATH

#RUN pip install keras 
# &&  apt-get install python-virtualenv
RUN R -e "install.packages(c('tidyr', 'ggplot2', 'reticulate'));"
# RUN R -e "library(reticulate); \
# 	  install.packages('tensorflow'); \
#           library(tensorflow); \
# 	  use_python('/usr/local/bin/python'); \
# 	  install.packages('keras')";
RUN R -e "install.packages('keras')";
RUN R -e "install.packages('pROC')";
#/usr/local/lib/R/site-library/00LOCK-processx/00new/processx


RUN echo "library(reticulate); use_python('/usr/local/bin/python')" > ~/.Rprofile
EXPOSE 8787

RUN adduser rstudio sudo
RUN apt-get -y install git
RUN pip install pillow

##################################################################################
###########  DEVTOOLS
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN  apt-get update \
  && apt-get -y build-dep libcurl4-gnutls-dev \
  && apt-get -y install libcurl4-gnutls-dev libssl-dev libgit2-dev \
  && R  -e "install.packages('devtools')";

##################################################################################
RUN mkdir -p ~/.R/rstudio/keybindings \
    && echo '{"commentUncomment" : "Cmd+/"}' > ~/.R/rstudio/keybindings/rstudio_bindings.json

RUN echo -e "#!/bin/bash\n echo 'running rstudio server' && echo 'go to http://0.0.0.0:8787' && echo -e 'login:\trstudio\npassword:\trstudio' &&  /usr/lib/rstudio-server/bin/rserver \"\$@\"" > /startserver.sh && chmod +x /startserver.sh
#ENTRYPOINT ["/usr/lib/rstudio-server/bin/rserver"]
RUN cat /startserver.sh
ENTRYPOINT ["/startserver.sh"]
#USER rstudio
CMD [ "--server-daemonize=0", "--server-app-armor-enabled=0"]

