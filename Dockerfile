FROM docker.io/centos:centos7
MAINTAINER crunchy

# Install postgresql deps
RUN rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm
RUN yum -y --enablerepo=centosplus install gettext epel-release && \
	yum install -y procps-ng postgresql94 postgresql94-contrib postgresql94-server openssh-clients hostname bind-utils  &&  \
	yum clean all -y

# set up cpm directory
#
RUN mkdir -p /opt/cpm/bin
RUN mkdir -p /opt/cpm/conf

RUN chown -R postgres:postgres /opt/cpm

# set environment vars
ENV PGROOT /usr/pgsql-9.4
ENV PGDATA /pgdata

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# add volumes to allow backup of postgres files
VOLUME ["/pgdata"]


# open up the postgres port
EXPOSE 5432

ADD bin /opt/cpm/bin
ADD conf /opt/cpm/conf

RUN setcap cap_chown,cap_fowner+ep /usr/bin/chown
RUN setcap cap_chown,cap_fowner+ep /usr/bin/chmod
RUN setcap cap_chown,cap_fowner+ep /opt/cpm/bin/start.sh
RUN setcap cap_chown,cap_fowner+ep /usr/pgsql-9.4/bin/pg_ctl
RUN setcap cap_chown,cap_fowner+ep /usr/pgsql-9.4/bin/initdb

RUN chown -R postgres:postgres /pgdata

USER postgres

CMD ["/opt/cpm/bin/start.sh"]

