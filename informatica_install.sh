#!/bin/sh
##########################################################################################
# Informatica Custom Installation Script for IDMC Secure Agent on Linux
# Requires 2nd HDD Disk for Data Volume and NFS Share for HA deployment
# Note: Comment out last section if NFS Share and HA option are not needed
########################################################################################## 

# Input Variables
rawdatadisk="/dev/sdb"
infauseruname="infauser"
infausergname="infauser"
infausergid="10001"
infauseruid="10001"
nfsclustershare="x.x.x.x:/nfsharename"
nfsclustershareoptions="vers=3,sec=sys"
#secagenturl will depend on the POD location 
secagenturl="https://xxxxx.informaticacloud.com/saas/download/installer/linux64/agent64_install_ng_ext.bin"

# Setup disk partion and label
/usr/sbin/parted ${rawdatadisk} mklabel gpt
/usr/sbin/parted -s ${rawdatadisk} unit mib mkpart primary 1 100%
/usr/sbin/parted -s ${rawdatadisk} set 1 lvm on

# Create LVM VG and LG
/usr/sbin/pvcreate ${rawdatadisk}1
/usr/sbin/vgcreate datavg ${rawdatadisk}1
/usr/sbin/lvcreate -l 100%FREE -n informaticalv01 datavg

# Format new LG with xfs file system
/usr/sbin/mkfs.xfs /dev/datavg/informaticalv01

# Add user and group
/usr/sbin/groupadd -g ${infausergid} ${infausergname}
/usr/sbin/useradd -u ${infauseruid} -g ${infausergid} -s /bin/bash -d /home/${infauseruname} -m -c "Informatica Agent" ${infauseruname}

# Prepare mountpoint, update fstab, mount and change permisions for Informatica LVM LV
/usr/bin/mkdir /opt/informatica
/usr/bin/echo "/dev/mapper/datavg-informaticalv01 /opt/informatica xfs defaults 0 0" >> /etc/fstab
/usr/bin/mount /opt/informatica
/usr/bin/chown ${infauseruname}:${infausergname} /opt/informatica

# Link Informatica Agent needed libary with existing library that provides same functionality (manually check to see if /usr/lib64/libnsl.so.2.0.0 exists)(if not install first)
/usr/bin/ln -s /usr/lib64/libnsl.so.2.0.0 /usr/lib64/libnsl.so.1
# Install additionally needed packages
yum install libidn.x86_64

# Update limits for user infauser
/usr/bin/cat << EOF1 > /etc/security/limits.d/90-${infauseruname}.conf
${infauseruname}        hard    core      unlimited
${infauseruname}        soft    core      unlimited
${infauseruname}        hard    nofile    32000
${infauseruname}        soft    nofile    32000
${infauseruname}        hard    stack     8192
${infauseruname}        soft    stack     8192
${infauseruname}        hard    nproc     32000
${infauseruname}        soft    nproc     32000
EOF1

# Download Informatica Agent install binaries and prepare for installation as infauser
cd /home/${infauseruname}
/usr/bin/wget ${secagenturl} -P /home/${infauseruname}/
/usr/bin/chown ${infauseruname}:${infausergname} /home/${infauseruname}/agent64_install_ng_ext.bin
/usr/bin/chmod 755 /home/${infauseruname}/agent64_install_ng_ext.bin

# Run Informatica Agent install in silent mode
/usr/sbin/runuser -l ${infauseruname} -c "/home/${infauseruname}/agent64_install_ng_ext.bin -i silent -DUSER_INSTALL_DIR=/opt/informatica/infaagent"

# Update infauser .bash_profile settings
/usr/sbin/runuser -l ${infauseruname} -c "/usr/bin/cat << EOF2 >> ~/.bash_profile
export JAVA_HOME=/opt/informatica/infaagent/jdk
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=/opt/protegrity/applicationprotector/java/lib
EOF2"

# Update SELinux to allow Informatica Agent components as services(check to see if SELinux is enabled)
/usr/sbin/semanage fcontext -a -t bin_t '/opt/informatica/infaagent/apps/agentcore/agent_start.sh'
/usr/sbin/restorecon -Fv /opt/informatica/infaagent/apps/agentcore/agent_start.sh
/usr/sbin/semanage fcontext -a -t bin_t '/opt/informatica/infaagent/apps/agentcore/infaagent'
/usr/sbin/restorecon -Fv /opt/informatica/infaagent/apps/agentcore/infaagent

# Create systemd services for Informatica Agent
/usr/bin/cat << EOF3 > /etc/systemd/system/informatica-intelligent-cloud-agent.service
[Unit]
Description=Informatica Intelligent Cloud Agent service
After=network.target remote-fs.target

[Service]
Type=simple
User=${infauseruname}
ExecStart=/opt/informatica/infaagent/apps/agentcore/agent_start.sh
ExecStop=/opt/informatica/infaagent/apps/agentcore/infaagent shutdown

[Install]
WantedBy=multi-user.target
EOF3

# Enable Informatica Agent and start services
/usr/bin/systemctl enable informatica-intelligent-cloud-agent.service
/usr/bin/systemctl start informatica-intelligent-cloud-agent.service
/usr/bin/systemctl status informatica-intelligent-cloud-agent.service

# Prepare mountpoint, update fstab, mount and change permisions for NFS cluster mount
/usr/bin/mkdir /opt/informatica_cluster
/usr/bin/echo "${nfsclustershare} /opt/informatica_cluster nfs ${nfsclustershareoptions} 0 0" >> /etc/fstab
/usr/bin/mount /opt/informatica_cluster
/usr/bin/chown ${infauseruname}:${infausergname} /opt/informatica_cluster