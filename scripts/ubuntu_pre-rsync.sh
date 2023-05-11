#!/usr/bin/env bash

# VuFind2 install path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
INSTALL_PATH=$SCRIPT_DIR'/../../NDL-VuFind2'

# Config file extensions
CfgExt=( ini yaml json )

# copy sample configs to ini files
cd $INSTALL_PATH/local/config/finna
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      cp $x $t
    fi
  done
done
cd
cd $INSTALL_PATH/local/config/vufind
for i in "${CfgExt[@]}"; do
  for x in *.$i.sample; do
    t=${x%.$i.sample}.$i
    if [[ -f $x ]] && [[ ! -f $t ]]; then
      cp $x $t
    fi
  done
done
