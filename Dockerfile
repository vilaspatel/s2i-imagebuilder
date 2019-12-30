# s2i-springboot : 12-08-2017
#
# springboot-java
#
FROM registry.redhat.io/openjdk/openjdk-11-rhel8
MAINTAINER vilas
# HOME in base image is /opt/app-root/src

# Builder version
ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,Springboot,builder"

# Install required util packages.
 # RUN yum -y update; \
  #  yum install tar -y; \
  #  yum install unzip -y; \
  #  yum install ca-certificates -y; \
  #  yum install sudo -y; \
  # yum clean all -y 

# Install OpenJDK 1.8, create required directories.
#RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    #yum clean all -y && \
    #mkdir -p /opt/openshift

# Install Maven 3.5.2
#ARG MAVEN_VER
#ENV MAVEN_VERSION $MAVEN_VER
#RUN (curl -fSL http://apachemirror.wuchna.com/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz | \
   # tar -zx -C /usr/local) && \
  #  mv /usr/local/apache-maven-3.6.3 /usr/local/maven && \
  #  ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
  #  mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2

# Install Gradle 4.4
#ARG GRADLE_VER
#ENV GRADLE_VERSION $GRADLE_VER
#RUN curl -fSL https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -o /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    #unzip /tmp/gradle-$GRADLE_VERSION-bin.zip -d /usr/local/ && \
    #rm /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    #mv /usr/local/gradle-$GRADLE_VERSION /usr/local/gradle && \
    #ln -sf /usr/local/gradle/bin/gradle /usr/local/bin/gradle && \
    #mkdir -p $HOME/.gradle && chmod -R a+rwX $HOME/.gradle

# Set the location of the mvn and gradle bin directories on search path
#ENV PATH=/usr/local/bin/mvn:/usr/local/bin/gradle:$PATH

# Set the default build type to 'Maven'
ENV BUILD_TYPE=Maven
USER root
# Drop the root user and make the content of /opt/openshift owned by user 1001
RUN chown -R 1001:1001 /deployments/data /home/jboss

# Change perms on target/deploy directory to 777
RUN chmod -R 777 /deployments/data /home/jboss

# Copy the S2I scripts to /usr/local/s2i
# sets io.openshift.s2i.scripts-url label that way.
COPY ./s2i/bin/ /usr/local/s2i
RUN  chmod -R 777 /usr/local/s2i

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["/usr/local/s2i/run"]
