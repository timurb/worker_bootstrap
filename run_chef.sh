#!/bin/sh

WORKDIR="$( dirname "$( readlink -f $0 )" )"

CONFIG="$WORKDIR/solo.rb"
[ -f "$CONFIG" ] || sed "s,@COOKBOOK_PATH@,$WORKDIR," "$CONFIG.template" > "$CONFIG"
chef-solo -j "$WORKDIR/node.json" -c "$CONFIG" $*
