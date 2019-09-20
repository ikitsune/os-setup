#!/bin/bash

# Make sure ovftool is in the path.
# On the mac:
#PATH=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/:$PATH
 
# I need to be given the output path and vmname.
if [ -z "$1" -o -z "$2" ]; then
  echo "output path and vm-name are required"
  exit 1
fi

DIR=$1
NAME=$2
 
cd $DIR
 
# I may be called multiple times.  If so bail early
if [ -f "${NAME}.ova" ]; then
  echo "OVA already created, skipping"
  exit 0
fi
 
if [ ! -f "${NAME}.vmx" ]; then
  echo "no ${NAME}.vmx file found"
  exit 1
fi
 
# bail on error
set -e
 
# remove floppy
sed '/floppy0\./d' ${NAME}.vmx > 1.tmp
echo 'floppy0.present = "FALSE"' >> 1.tmp
 
# remove CD
sed '/ide1:0\.file/d' 1.tmp | sed '/ide1:0\.present/d' > 2.tmp
echo 'ide1:0.present = "FALSE"' >> 2.tmp
 
mv 2.tmp ${NAME}.vmx
 
ovftool -dm=thin --compress=1 ${NAME}.vmx ${NAME}.ova
