#!/bin/sh
list_dirs=("bin" "boot" "etc" "lib" "lib64" "opt" "root" "sbin" "srv" "usr" "var")
system_dirs=("proc" "sys" "dev" "run" "tmp")
dtb_delta="/var/lib/distrobox-delta"  #### need real file system, not overlayfs
dummy_image_name="dummy-image-distrobox"
function overlay_create_and_mount(){
    operation_dir="$dtb_delta/$box_name"
    sudo mkdir -p $operation_dir
        for i in ${list_dirs[@]} ; do
         sudo mkdir -p $operation_dir/.overlay/work-$i
         sudo mkdir -p $operation_dir/.overlay/upper-$i
         sudo mkdir -p $operation_dir/$i
         if ! mountpoint -q $operation_dir/$i > /dev/null; then
            sudo mount  -t overlay overlay -o lowerdir=/$i,upperdir=$operation_dir/.overlay/upper-$i,workdir=$operation_dir/.overlay/work-$i $operation_dir/$i
         fi
        done
}
function dummy_image_create(){
if ! sudo podman image exists $dummy_image_name:1 ; then
escape_dir=$(mktemp -d -p /tmp)
tarball_dir=$(mktemp -d -p /tmp)
    for i in ${system_dirs[@]} ; do
        mkdir $escape_dir/$i
    done
    for i in ${list_dirs[@]} ; do
       mkdir $escape_dir/$i
    done
   cd $escape_dir
   tar -cf $tarball_dir/$dummy_image_name.tar *
    sudo podman image import $tarball_dir/$dummy_image_name.tar --message tag $dummy_image_name:1
fi
}
function distrobox_invocation(){
    for i in ${list_dirs[@]} ; do
        volume_mounts="${volume_mounts[@]} --volume $dtb_delta/$box_name/$i:/$i"
    done
    distrobox create \
    $box_name \
    --root \
    --pre-init-hooks "if [ ! -f /etc/vbox.provisioned ] ; then zypper al kernel-firm\\\*; zypper --non-interactive in -R virtualbox virtualbox-qt virtualbox-vnc; echo -e '#!/bin/bash\\\\n\\\\nkernel=\\\$(uname -r)\\\\nfor i in \\\$(find /usr/lib/modules/\\\$kernel/extra); do sudo insmod \\\$i 2>/dev/null; done ; echo 'press enter to detach' ; VirtualBox %U \\&' > /usr/local/bin/vbox-entrypoint ; chmod +x /usr/local/bin/vbox-entrypoint; touch /etc/vbox.provisioned; fi" \
    --init-hooks "usermod -aG vboxusers $USER" \
    --image localhost/$dummy_image_name:1 \
    --additional-flags "--cap-add=ALL" \
    ${volume_mounts[@]}

}
printf "###########################################################\n"
printf "                Distrobox Delta                               \n"
printf "###########################################################\n"
function main(){
if ! sudo podman container exists $box_name ; then
    overlay_create_and_mount
    dummy_image_create
    distrobox_invocation
    distrobox enter --root $box_name -- /usr/local/bin/vbox-entrypoint &
else
    overlay_create_and_mount
    distrobox enter --root $box_name -- /usr/local/bin/vbox-entrypoint &
fi
}
if [ ! -z $1 ] ; then
    box_name=$1
    main
else
    box_name="opensuse-vbox-delta"
    main
fi
