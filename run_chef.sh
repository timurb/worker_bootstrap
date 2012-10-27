#!/bin/sh

WORKDIR="$( dirname "$( readlink -f $0 )" )"

CONFIG="$WORKDIR/solo.rb"
USERDATAFILE="$WORKDIR/userdata.json"
NODEJSON="$WORKDIR/node.json"

# generate the chef config from the template
[ -f "$CONFIG" ] || sed "s,@COOKBOOK_PATH@,$WORKDIR," "$CONFIG.template" > "$CONFIG"

# retrieve node.json from URL from userdata
JSON_URL="$(curl -s http://169.254.169.254/latest/user-data)"
[ -n "$JSON_URL" ] && curl -s "$JSON_URL" > "$USERDATAFILE"

# if there is a correct JSON replace default node.json with that
[ -x "$WORKDIR/validate_json" ] && "$WORKDIR/validate_json" "$USERDATAFILE" && mv -f "$USERDATAFILE" "$NODEJSON"


chef-solo -j "$NODEJSON" -c "$CONFIG" $*
