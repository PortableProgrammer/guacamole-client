Apache Guacamole for multi-arch
===============================

This image is a repackage of the official [Apache Guacamole](https://hub.docker.com/r/guacamole/guacamole) for amd64, armv7/armhf, and arm64. The biggest change is swapping in `tomcat:8.5-jdk8-adoptopenjdk-hotspot` for `tomcat:8.5-jdk8`, as the rest of the tomcat 8.5 images don't support armv7.
