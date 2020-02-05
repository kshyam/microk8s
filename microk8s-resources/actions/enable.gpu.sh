#!/usr/bin/env bash

set -e

source $SNAP/actions/common/utils.sh

echo "Enabling NVIDIA GPU"
if lsmod | grep "nvidia" &> /dev/null ; then
  echo "NVIDIA kernel module detected"
else
  echo "Aborting: NVIDIA kernel module not loaded."
  echo "Please ensure you have CUDA capable hardware and the NVIDIA drivers installed."
  exit 1
fi

mkdir -p ${SNAP_DATA}/var/lock
touch ${SNAP_DATA}/var/lock/gpu

# Copy Nvidia drivers into the correct place.
cp /var/lib/snapd/lib/gl/libnv* /usr/lib/x86_64-linux-gnu/
cp /var/lib/snapd/lib/gl/libcuda* /usr/lib/x86_64-linux-gnu/
cp /var/lib/snapd/lib/gl/libEGL_nvidia.so* /usr/lib/x86_64-linux-gnu/
cp /var/lib/snapd/lib/gl/libGLX_nvidia.so* /usr/lib/x86_64-linux-gnu/
cp /var/lib/snapd/lib/gl/libGLESv*_nvidia.so* /usr/lib/x86_64-linux-gnu/

snapctl restart "${SNAP_NAME}.daemon-containerd"
containerd_up=$(wait_for_service containerd)
if [[ $containerd_up == fail ]]
then
  echo "Containerd did not start on time. Proceeding."
fi

if ! [ -e "$SNAP_DATA/var/lock/clustered.lock" ]
then
  # Allow for some seconds for containerd processes to start
  sleep 10
  "$SNAP/microk8s-enable.wrapper" dns
  echo "Applying manifest"
  use_manifest gpu apply
  echo "NVIDIA is enabled"
fi
