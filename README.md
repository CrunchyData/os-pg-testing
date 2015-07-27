some pg testing on openshift


## Openshift Configuration

This example uses Openshift/Kube EmptyDir volumes to hold 
the Postgresql data files.

For this to work, you will need to configure your 'restricted'
Openshift settings to include:

[root@origin openshift]# oc get scc restricted
NAME         PRIV      CAPS             HOSTDIR   SELINUX     RUNASUSER
restricted   false     [CHOWN FOWNER]   false     MustRunAs   RunAsAny

This can be set by entering the following commands, using 192.168.0.7 as
your host IP:

oc config use-context default/192-168-0-107:8443/system:admin
oc edit scc restricted --config=/var/lib/openshift/openshift.local.config/master/admin.kubeconfig
#
allowHostDirVolumePlugin: false
allowHostNetwork: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities:
- CHOWN
- FOWNER
apiVersion: v1
groups:
- system:authenticated
kind: SecurityContextConstraints
metadata:
  creationTimestamp: 2015-07-26T18:04:06Z
  name: restricted
  resourceVersion: "392"
  selfLink: /api/v1/securitycontextconstraints/restricted
  uid: b4fd5972-33c0-11e5-ba12-74d435ba249b
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs


## standalone.json

This openshift template will create a single Postgresql instance.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f standalone.json | oc create -f -
~~~~~~~~~~~~~~~~

Then in the running standalone pod, you can run the following
command to test the database:

~~~~~~~~~~~~~~
psql -h pg-standalone.pgproject.svc.cluster.local -U postgres postgres
~~~~~~~~~~~~~~


## master-slave.json

This openshift template will create a single master Postgresql instance
and a single slave instance, configured for streaming replication.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f master-slave.json | oc create -f -
~~~~~~~~~~~~~~~~

Then in the running standalone pod, you can run the following
command to test the database:

~~~~~~~~~~~~~~
psql -h pg-master.pgproject.svc.cluster.local -U postgres postgres
psql -h pg-slave.pgproject.svc.cluster.local -U postgres postgres
~~~~~~~~~~~~~~

## master-slave-rc.json

This openshift template will create a single master Postgresql instance
and a single slave instance, configured as a Replication Controller, allowing
you to scale up the number of slave instances.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f master-slave-rc.json | oc create -f -
~~~~~~~~~~~~~~~~

Connect to the postgresql instances with the following:

~~~~~~~~~~~~~~
psql -h pg-master-rc.pgproject.svc.cluster.local -U user postgres
psql -h pg-slave-rc.pgproject.svc.cluster.local -U user postgres
~~~~~~~~~~~~~~

## Scaling up Slaves
Here is an example of increasing or scaling up the Postgres 'slave'
pods to 2:
~~~~~~~~~~
oc scale rc pg-slave-rc-1 --replicas=2
~~~~~~~~~~

## Verify Postgresql Replication is Working

Enter the following commands to verify the Postgresql 
replication is working.

First, find the pods:

~~~~~~~~~~~~~~~~
[root@origin openshift]# oc get pods
NAME                      READY     STATUS    RESTARTS   AGE
docker-registry-1-vrli4   1/1       Running   1          6h
pg-master-rc-1-n5z8r      1/1       Running   0          15m
pg-slave-rc-1-4gsfo       1/1       Running   0          15m
pg-slave-rc-1-f1rlo       1/1       Running   0          11m
~~~~~~~~~~~~~~~~~

Next, exec into the master pod:

~~~~~~~~~~~~~~~~~~~~~
[root@origin openshift]# oc exec -it pg-master-rc-1-n5z8r /bin/bash

~~~~~~~~~~~~~~~~~~~~~~~

Next, run the psql command to view the replication status, you
should see something similar to this output, in this example 
we are replicating database state to 2 pods:

~~~~~~~~~~~~~~~~~
bash-4.2$ psql -U postgres postgres
psql (9.4.4)
Type "help" for help.

postgres=# select * from pg_stat_replication;
 pid | usesysid | usename | application_name | client_addr | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_location | write_location | flush_location | replay_location | sync_priority | sync_state 
 -----+----------+---------+------------------+-------------+-----------------+-------------+-------------------------------+--------------+-----------+---------------+----------------+----------------+-----------------+---------------+------------
   86 |    16384 | master  | walreceiver      | 172.17.0.11 |                 |       34522 | 2015-07-26 20:26:39.688865-04 |              | streaming | 0/5000210     | 0/5000210      | 0/5000210      | 0/5000210       |             0 | async
    130 |    16384 | master  | walreceiver      | 172.17.0.13 |                 |       37211 | 2015-07-26 20:30:41.29627-04  |              | streaming | 0/5000210     | 0/5000210      | 0/5000210      | 0/5000210       |             0 | async
    (2 rows)
~~~~~~~~~~~~~~~~~

