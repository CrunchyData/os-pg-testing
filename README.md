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

## master-slave.json

This openshift template will create a single master Postgresql instance
and a single slave instance, configured for streaming replication.
