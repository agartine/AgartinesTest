#!/bin/sh
# Run ovpn-init and set up as secondary instance

# Options
# [yes] - Accept License
# [yes] - Primary, [no] backup server
# Do you wish to login to the Admin UI as "openvpn"?
#     - license key

cat <<EOF | sudo ovpn-init --force
yes
no
yes

EOF
