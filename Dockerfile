FROM openjdk:8-jre

LABEL maintainer "Jon Clausen <jclausen@ortussolutions.com>"
LABEL repository "https://github.com/Ortus-Solutions/docker-commandbox"

#Since alpine runs as a single user, we need to create a "root" direcotry
ENV HOME /root

#Basic Dependencies
RUN apt-get update
RUN apt-get install --assume-yes jq

### Directory Mappings ###
# APP_DIR = the directory where the application runs
ENV APP_DIR /app
WORKDIR $APP_DIR


# BIN_DIR = Where the box binary goes
ENV BIN_DIR /usr/bin
WORKDIR $BIN_DIR

# BUILD_DIR = WHERE runtime scripts go
ENV BUILD_DIR $HOME/build
WORKDIR $BUILD_DIR

# Copy file system
COPY ./test/ ${APP_DIR}/
COPY ./build/ ${BUILD_DIR}/
RUN ls -la ${BUILD_DIR}
RUN chmod +x $BUILD_DIR/*.sh

#Commandbox Installation
RUN curl --location 'https://www.ortussolutions.com/parent/download/commandbox/type/bin' -o /tmp/box.zip
RUN unzip /tmp/box.zip -d ${BIN_DIR} && chmod +x ${BIN_DIR}/box
RUN echo "$(box version) successfully installed"

#CFConfig Installation
RUN box install commandbox-cfconfig
RUN ${BUILD_DIR}/optimize.sh

ENV HEALTHCHECK_URI "http://127.0.0.1:${PORT}/"
HEALTHCHECK --interval=1m --timeout=30s --retries=5 CMD curl --fail ${HEALTHCHECK_URI} || exit 1


# Port Mappings
ENV PORT ${PORT:-8080}
ENV SSL_PORT ${SSL_PORT:-8443}
EXPOSE ${PORT} ${SSL_PORT}

CMD $BUILD_DIR/run.sh
