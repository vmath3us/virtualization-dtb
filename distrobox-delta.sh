#!/bin/sh
list_dirs=("bin" "boot" "etc" "lib" "lib64" "opt" "root" "sbin" "srv" "usr" "var")
system_dirs=("proc" "sys" "dev" "run" "tmp")
dtb_delta="/var/lib/distrobox-delta"  #### need real file system, not overlayfs
box_name="opensuse-vbox-delta"
dummy_image_name="dummy-image-distrobox"
function overlay_create_and_mount(){
    operation_dir="$dtb_delta/$box_name"
    sudo mkdir -p $operation_dir
        for i in ${list_dirs[@]} ; do
         sudo mkdir -p $operation_dir/overlay/work-$i
         sudo mkdir -p $operation_dir/overlay/upper-$i
         sudo mkdir -p $operation_dir/$i
         if ! mountpoint -q $operation_dir/$i > /dev/null; then
            sudo mount  -t overlay overlay -o lowerdir=/$i,upperdir=$operation_dir/overlay/upper-$i,workdir=$operation_dir/overlay/work-$i $operation_dir/$i
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
   rm -rf $escape_dir $tarball_dir
fi
}
function distrobox_invocation(){
    for i in ${list_dirs[@]} ; do
        volume_mounts="${volume_mounts[@]} --volume $dtb_delta/$box_name/$i:/$i"
    done
    distrobox create \
    $box_name \
    --root \
    --image localhost/$dummy_image_name:1 \
    --additional-flags "--cap-add=ALL" \
    ${volume_mounts[@]}

}
printf "###########################################################\n"
printf "                Distrobox Delta                               \n"
printf "###########################################################\n"
function main(){
    overlay_create_and_mount
    dummy_image_create
    distrobox_invocation
}
if [ ! -z $box_name ] ; then
main
fi
