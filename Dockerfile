###### Supervisord image
FROM centos:centos7
MAINTAINER "Christian Kniep <christian@qnib.org>"


ADD etc/yum.repos.d/qnib.repo /etc/yum.repos.d/qnib.repo
RUN yum clean all

## supervisord
RUN yum install -y python-meld3 python-setuptools python-supervisor
ADD etc/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor
RUN sed -i -e 's/nodaemon=false/nodaemon=true/' /etc/supervisord.conf
ADD usr/local/bin/supervisor_daemonize.sh /usr/local/bin/supervisor_daemonize.sh

# misc
RUN yum install -y bind-utils vim

##### USER
# Set (very simple) password for root
RUN echo "root:root"|chpasswd
ADD root/ssh /root/.ssh
ADD root/bashrc /root/.bashrc
ADD root/bash_profile /root/.bash_profile
RUN chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa
RUN chown -R root:root /root/

### SSHD
RUN yum install -y openssh-server openssh-clients initscripts
RUN mkdir -p /var/run/sshd
ADD root/bin/startup_sshd.sh /root/bin/startup_sshd.sh
RUN sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
RUN sed -i -e 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/sshd_config
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini

# We do not care about the known_hosts-file and all the security
####### Highly unsecure... !1!! ###########
RUN echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "        AddressFamily inet" >> /etc/ssh/ssh_config

# SLURM
RUN yum clean all;yum install -y slurm

# etcd+skydns
ADD usr/local/bin/etcdctl /usr/local/bin/etcdctl
RUN yum install -y skydns etcd

### compute-stuff
# Install dependencies
RUN yum install -y openmpi
# Application libs
RUN yum install -y gsl libgomp

# python-dependency
RUN yum install -y python-docopt PyYAML

RUN yum install -y nc

CMD /bin/supervisord -c /etc/supervisord.conf
