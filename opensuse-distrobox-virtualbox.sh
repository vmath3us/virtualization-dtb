#!/bin/sh
# Assuming host is opensuse tumbleweed/Aeon/Kalpa
#
# keep the host and container always updating at the same speed,
# and at the exact same kernel version
if ! sudo podman container exists opensuse-vbox ; then
distrobox create opensuse-vbox \
--image registry.opensuse.org/opensuse/distrobox \
--additional-flags "--cap-add=ALL" \
--pre-init-hooks "if [ ! -f /etc/vbox.provisioned ] ; then zypper --non-interactive in -R virtualbox virtualbox-qt virtualbox-vnc virtualbox-host-source kernel-devel kernel-default-devel ; echo -e '#!/bin/bash\\\\nsudo /usr/sbin/vboxconfig ; for i in vboxautostart-service vboxdrv ; do sudo systemctl unmask \\\$i ; sudo systemctl start \\\$i ; done ; echo 'is ok close term' ; exec VirtualBox \& ' > /usr/local/bin/vbox-entrypoint ; chmod +x /usr/local/bin/vbox-entrypoint; touch /etc/vbox.provisioned; fi" \
--init-hooks "usermod -aG vboxusers $USER" \
--root \
--init
fi
vbox_open='distrobox enter opensuse-vbox --root -- /usr/local/bin/vbox-entrypoint'
printf '\e[1;32m%s\e[m\n' "run ${vbox_open} ..."
${vbox_open}
