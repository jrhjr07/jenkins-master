FROM ubuntu:xenial
MAINTAINER Jim Hopkins <jim@jhopkins.us>

# expose the port
EXPOSE 8080
# required to make docker in docker to work
VOLUME /var/lib/docker

# default jenkins home directory
ENV JENKINS_HOME /var/jenkins
# set our user home to the same location
ENV HOME /var/jenkins

# set our wrapper
ENTRYPOINT ["/usr/local/bin/docker-wrapper"]
# default command to launch jenkins
CMD java -jar /usr/share/jenkins/jenkins.war

# setup our local files first
ADD docker-wrapper.sh /usr/local/bin/docker-wrapper

# for installing docker related files first
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe > /etc/apt/sources.list.d/universe.list
# apparmor is required to run docker server within docker container
RUN apt-get update -qq && apt-get install -qqy wget curl git iptables ca-certificates apparmor

# for jenkins
RUN echo deb http://pkg.jenkins-ci.org/debian binary/ >> /etc/apt/sources.list \
    && wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
RUN apt-get update -qq && apt-get install -qqy jenkins

# now we install docker in docker - thanks to https://github.com/jpetazzo/dind
# We install newest docker into our docker in docker container
RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
  && tar --strip-components=1 -xvzf docker-latest.tgz -C /usr/local/bin \
  && chmod +x /usr/local/bin/docker

RUN cd /tmp \
  && curl -Lk https://releases.rancher.com/compose/latest/rancher-compose-linux-amd64.tar.gz > rancher-compose.tar.gz \
  && tar xzvf rancher-compose.tar.gz \
  && mv rancher-compose*/rancher-compose /usr/local/bin \
  && rm -rf rancher-compose.tar.gz && rmdir rancher-compose* \
  && curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose
