#!/usr/bin/expect -f
#
# This Expect script was generated by autoexpect on Thu Jun 30 17:33:54 2016
# Expect and autoexpect were both written by Don Libes, NIST.
#
# Note that autoexpect does not guarantee a working script.  It
# necessarily has to guess about certain things.  Two reasons a script
# might fail are:
#
# 1) timing - A surprising number of programs (rn, ksh, zsh, telnet,
# etc.) and devices discard or ignore keystrokes that arrive "too
# quickly" after prompts.  If you find your new script hanging up at
# one spot, try adding a short sleep just before the previous send.
# Setting "force_conservative" to 1 (see below) makes Expect do this
# automatically - pausing briefly before sending each character.  This
# pacifies every program I know of.  The -c flag makes the script do
# this in the first place.  The -C flag allows you to define a
# character to toggle this mode off and on.

set force_conservative 0  ;# set to 1 to force conservative mode even if
			  ;# script wasn't run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

#
# 2) differing output - Some programs produce different output each time
# they run.  The "date" command is an obvious example.  Another is
# ftp, if it produces throughput statistics at the end of a file
# transfer.  If this causes a problem, delete these patterns or replace
# them with wildcards.  An alternative is to use the -p flag (for
# "prompt") which makes Expect only look for the last line of output
# (i.e., the prompt).  The -P flag allows you to define a character to
# toggle this mode off and on.
#
# Read the man page for more info.
#
# -Don

# get hostname
set hostname [lindex $argv 0]

set timeout -1
spawn sudo ambari-server setup-security
match_max 100000
expect -exact "Using python  /usr/bin/python\r
Security setup options...\r
===========================================================================\r
Choose one of the following options: \r
  \[1\] Enable HTTPS for Ambari server.\r
  \[2\] Encrypt passwords stored in ambari.properties file.\r
  \[3\] Setup Ambari kerberos JAAS configuration.\r
  \[4\] Setup truststore.\r
  \[5\] Import certificate to truststore.\r
===========================================================================\r
Enter choice, (1-5): "
send -- "1\r"
expect -exact "1\r
Do you want to configure HTTPS \[y/n\] (y)? "
send -- "y\r"
expect -exact "y\r
SSL port \[8443\] ? "
send -- "\r"
expect -exact "\r
Enter path to Certificate: "
send -- "/home/centos/$hostname.cert.pem\r"
expect -exact "/home/centos/$hostname.cert.pem\r
Enter path to Private Key: "
send -- "/home/centos/$hostname.key.pem\r"
expect -exact "/home/centos/$hostname.key.pem\r
Please enter password for Private Key: "
send -- "\r"
expect eof
