set -e

echo "Testing inline manifest ..."
bundle exec puppet mgmtgraph print --code 'notify { "hi": }' | grep -q msg:

echo "Testing manifest file ..."
manifest=$(mktemp spec-manifest-XXXXXX.pp)
echo 'notify { "hi": }' >$manifest
bundle exec puppet mgmtgraph print --manifest $manifest | grep -q msg:
rm $manifest
