#!/bin/bash
set -euo pipefail

preparePatching()
{
  echo "Preparing patch..."
  PATCHNETCORESDK="$CLINETCORESDK.patch"
  mkdir $PATCHNETCORESDK
  cp $CPARGS --recursive --force $CLINETCORESDK/* $PATCHNETCORESDK
  
  PATCHNETCORESDKSHAREDROOT="$PATCHNETCORESDK/shared/Microsoft.NETCore.App"
  SHAREDVERSIONS=($(ls --reverse $PATCHNETCORESDKSHAREDROOT))
  PATCHNETCORESDKSHAREDPATH="$PATCHNETCORESDKSHAREDROOT/${SHAREDVERSIONS[0]}"
  
  PATCHNETCORESDKSDKROOT="$PATCHNETCORESDK/sdk"
  SDKVERSIONS=($(ls --reverse $PATCHNETCORESDKSDKROOT))
  PATCHNETCORESDKSDKPATH="$PATCHNETCORESDKSDKROOT/${SDKVERSIONS[0]}"
  
  PATCHNETCORESDKHOSTROOT="$PATCHNETCORESDK/host/fxr"
  HOSTVERSIONS=($(ls --reverse $PATCHNETCORESDKHOSTROOT))
  PATCHNETCORESDKHOSTPATH="$PATCHNETCORESDKHOSTROOT/${HOSTVERSIONS[0]}"
}

patchCoreClr()
{
   echo "Patching runtime binaries..."
   cp $CPARGS $CORECLRBINDIR/*so "$PATCHNETCORESDKSHAREDPATH"
   cp $CPARGS "$CORECLRBINDIR/corerun" "$PATCHNETCORESDKSHAREDPATH"
   cp $CPARGS "$CORECLRBINDIR/crossgen" "$PATCHNETCORESDKSHAREDPATH"
}

patchCoreFx()
{
   echo "Patching framework binaries..."
   cp $CPARGS $COREFXBINDIR/System.* "$PATCHNETCORESDKSHAREDPATH"
}

patchCoreSetup()
{
  echo "Patching SDK binaries..."
  cp $CPARGS "$CORESETUPBINDIR/dotnet" "$PATCHNETCORESDK"
  cp $CPARGS "$CORESETUPBINDIR/dotnet" "$PATCHNETCORESDKSHAREDPATH"
  cp $CPARGS "$CORESETUPBINDIR/libhostpolicy.so" "$PATCHNETCORESDKSHAREDPATH"
  cp $CPARGS "$CORESETUPBINDIR/libhostfxr.so" "$PATCHNETCORESDKSHAREDPATH"
  cp $CPARGS "$CORESETUPBINDIR/libhostpolicy.so" "$PATCHNETCORESDKSDKPATH"
  cp $CPARGS "$CORESETUPBINDIR/libhostfxr.so" "$PATCHNETCORESDKSDKPATH"
  cp $CPARGS "$CORESETUPBINDIR/libhostfxr.so" "$PATCHNETCORESDKHOSTPATH"
}

finalizePatching()
{
  echo "Finalizing patch..."
  cp --recursive --force $PATCHNETCORESDK/* $CLINETCORESDK
  rm -dfr $PATCHNETCORESDK
}

CLINETCORESDK=""
CORECLRBINDIR=""
COREFXBINDIR=""
CORESETUPBINDIR=""
CPARGS="--force"

while [[ $# -gt 0 ]]
  do
    key="$1"

    case $key in
      -p|--netcore_sdk_path)
      CLINETCORESDK="$2"
      shift 2
      ;;
      -c|--coreclr_repo_path)
      CORECLRBINDIR="$2/bin/Product/Linux.x64.Release"
      shift 2
      ;;
      -f|--corefx_repo_path)
      COREFXBINDIR="$2/bin/Linux.x64.Release/native"
      #Older builds of corefx place binaries in "Native" instead of "native"
      if [[ ! -d $COREFXBINDIR ]]; then
        COREFXBINDIR="$2/bin/Linux.x64.Release/Native"
      fi
      shift 2
      ;;
      -s|--coresetup_repo_path)
      CORESETUPOSPATH=($(ls $2/artifacts))
      CORESETUPBINDIR="$2/artifacts/${CORESETUPOSPATH[0]}/corehost"
      shift 2
      ;;
      -v|--verbose)
      CPARGS="$CPARGS --verbose"
      shift 1
      ;;
      *)
      echo "Unknown argument specified '$key'."
      exit 1
    esac
done

missingdir="0"
if [[ ! -d $CLINETCORESDK ]]; then
  echo "Error: Unable to find CLI directory to patch, specify CLI directory with the '--netcore_sdk_path' option."
  missingdir="1"
fi
if [[ ! -d $CORECLRBINDIR ]]; then
  echo "Error: Unable to find CoreClr bin directory, specify CoreClr repo path with the '--coreclr_repo_path' option."
  missingdir="1"
fi
if [[ ! -d $COREFXBINDIR ]]; then
  echo "Error: Unable to find CoreFx bin directory, specify CoreFx repo path with the '--corefx_repo_path' option."
  missingdir="1"
fi
if [[ ! -d $CORESETUPBINDIR ]]; then
  echo "Error: Unable to find CoreSetup bin directory, specify CoreSetup repo path with the '--coresetup_repo_path' option."
  missingdir="1"
fi
if [[ "$missingdir" == "1" ]]; then
  exit 1
fi

preparePatching
patchCoreClr
patchCoreFx
patchCoreSetup
finalizePatching

exit 0