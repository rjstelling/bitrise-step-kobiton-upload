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

BASICAUTH=`echo -n $KUSERNAME:$KAPIKEY | base64`

echo "Using Auth: $BASICAUTH"

JSON="{\"filename\":\"${APPNAME}.apk\",\"appId\":$APPID}"
curl --silent -X POST https://api.kobiton.com/v1/apps/uploadUrl \
  -H 'Authorization: Basic bGlvbmhlYXJ0OjAyYWE4YmQwLTMyZTQtNGQxZi04NTdkLTE0YThhNWYzMWJhMQ==' \
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

JSON="{\"filename\":\"${APPNAME}.apk\",\"appPath\":\"${KAPPPATH}\"}"
curl -X POST https://api.kobiton.com/v1/apps \
  -H "Authorization: Basic $BASICAUTH" \
  -H 'Content-Type: application/json' \
  -d $JSON
  
echo "...done"

envman add --key KOBITON_UPLOAD_URL --value ${UPLOADURL}
envman add --key KOBITON_APP_PATH --value ${KAPPPATH}

#echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:
envman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'
# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
