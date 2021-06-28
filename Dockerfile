#
# Dockerfile for guacamole-client
#

# Use args for Tomcat image label to allow image builder to choose alternatives
# such as `--build-arg TOMCAT_JRE=jre8-alpine`
#
ARG TOMCAT_VERSION=8.5
# Default to a version that supports armv7 as well as arm64
ARG TOMCAT_JRE=jdk8-adoptopenjdk-hotspot
ARG GUACAMOLE_VERSION=1.3.0

# Start with the official Tomcat distribution
FROM tomcat:${TOMCAT_VERSION}-${TOMCAT_JRE}

# Copy the download script
COPY ./scripts/* /opt/install/

# Run the download
RUN /opt/install/get-guacamole-artifacts.sh ${GUACAMOLE_VERSION} /opt/guacamole \
    && rm -rf /opt/install

# Create a new user guacamole
ARG UID=1001
ARG GID=1001
RUN groupadd --gid $GID guacamole
RUN useradd --system --create-home --shell /usr/sbin/nologin --uid $UID --gid $GID guacamole

# Run with user guacamole
USER guacamole

# Start Guacamole under Tomcat, listening on 0.0.0.0:8080
EXPOSE 8080
CMD ["/opt/guacamole/bin/start.sh" ]
