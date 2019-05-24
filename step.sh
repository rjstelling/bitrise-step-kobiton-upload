#!/bin/bash
set -ex

# Install ack
curl https://beyondgrep.com/ack-2.22-single-file > /usr/local/bin/ack && chmod 0755 /usr/local/bin/ack

hash ack 2>/dev/null || { echo >&2 "ack required, but it's not installed."; exit 1; }

APPNAME=${kobiton_app_name}
APPPATH=${kobiton_app_path}
APPID=${kobiton_app_id}
KUSERNAME=${kobiton_user_id}
KAPIKEY=${kobiton_api_key}
APPSUFFIX=${kobiton_app_type}

BASICAUTH=`echo -n $KUSERNAME:$KAPIKEY | base64`

echo "Using Auth: $BASICAUTH"

if [ -z "$APPID" ]; then
  JSON="{\"filename\":\"${APPNAME}.${APPSUFFIX}\"}"
else
  JSON="{\"filename\":\"${APPNAME}.${APPSUFFIX}\",\"appId\":$APPID}"
fi

curl --silent -X POST https://api.kobiton.com/v1/apps/uploadUrl \
  -H "Authorization: Basic $BASICAUTH" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d $JSON \
  -o ".tmp.response.json"

UPLOADURL=`cat ".tmp.response.json" | ack -o --match '(?<=url\":")([_\%\&=\?\.aA-zZ0-9:/-]*)'`
KAPPPATH=`cat ".tmp.response.json" | ack -o --match '(?<=appPath\":")([_\%\&=\?\.aA-zZ0-9:/-]*)'`

echo "Uploading: ${APPNAME} (${APPPATH})"
echo "URL: ${UPLOADURL}"

curl  --progress-bar -T "${APPPATH}" -H "Content-Type: application/octet-stream" -H "x-amz-tagging: unsaved=true" -X PUT "${UPLOADURL}"
#--verbose

echo "Processing: ${KAPPPATH}"

JSON="{\"filename\":\"${APPNAME}.${APPSUFFIX}\",\"appPath\":\"${KAPPPATH}\"}"
curl -X POST https://api.kobiton.com/v1/apps \
  -H "Authorization: Basic $BASICAUTH" \
  -H 'Content-Type: application/json' \
  -d $JSON

echo "...done"

envman add --key KOBITON_UPLOAD_URL --value ${UPLOADURL}
envman add --key KOBITON_APP_PATH --value ${KAPPPATH}

exit 0
