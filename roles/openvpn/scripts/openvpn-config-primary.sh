#!/bin/sh
# Run ovpn-init and set up as primary instance

# Options
# [yes] - Accept License
# [yes] - Primary, [no] backup server
# 1 - bind to all interfaces
# 943 - admin ui port
# 443 - daemon port
# yes - client traffic routed through vpn
# yes - client dns traffic through vpn
# no  - use local auth
# yes - access private subnets
# yes - openvpn as user
#     - license key

cat <<EOF | sudo ovpn-init --force
yes
yes
1
943
443
yes
yes
no
yes
yes

EOF
