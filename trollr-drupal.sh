#!/bin/bash

#
# Drupal site blocked IPs comparision and additions
#
# Written by: Ryan Johnson [ ryanj@ucar.edu ]
# Created: April 2021
# Updated: April 2021
#
# - takes a list of known bad actor IPs
# - pulls current list of IPs from Drupal table blocked_ips
# - compares the list and manually adds to the table via terminus drush
#





###
### files & variables ###
###
# file for the list of IPs that are known bad actors
fileTrolls=`cat trolls.dat`

# counter for how many got banned
counterBanned=0


###
### functions ###
###
# check if a user is logged into terminus
# script stops if user is not logged in
terminus_auth_check() {
	# check if user is logged into terminus
	response=`terminus auth:whoami`

	# check the result
	# not logged in so let the user know
	if [ "$response" == "" ]; then
		echo "you are not authenticated with terminus, please login and re-run the script"
		exit 0
	# user login found so make sure its correct user
	else
		echo "logged in as $response"
	fi
}



###
### main ###
###
# check for logged in user
terminus_auth_check

# grab the sites
echo "grabbing site list..."
terminus site:list --fields="name"

# set the site to use
read -p 'type in site name and press [Enter] to start trollr on: ' SITENAME

# display status message while it gathers IPs from Drupal
printf "\n"
printf "grabbing list of blocked IPs from ${SITENAME} live environment... \n"

# grab the list of IPs already blocked from the site
fileDrupal=`terminus drush ${SITENAME}.live -- sql-query 'SELECT ip FROM blocked_ips' 2>/dev/null`

# display status message while it compares the drupal IPs to known bad actor IPs
printf "comparing list of blocked IPs to known bad actor list... \n\n"

# set the new IPs that will be added to the table
diffIPs=$(comm -23 <(tr ' ' '\n' <<<"$fileTrolls" | sort) <(tr ' ' '\n' <<<"$fileDrupal" | sort))

# get the number of IPs
numDiff=`echo -n "$diffIPs" | grep -c '^'`

# display and ask to continue
read  -p "$numDiff number of new IPs to block, continue? [y/n] " yn
case $yn in
	[Yy]* ) 
		# before looping inform user
		printf "\n"
		printf "starting loop, this may take a while depending on the number of additions...\n"

		# yes so loop thru list and add to table
		for banIP in $diffIPs; do
			# quick echo
			printf "adding entry for - ${banIP}"

			# terminus call
			terminus drush ${SITENAME}.live -- sql-query 'INSERT IGNORE INTO blocked_ips SET ip = "'$banIP'"' 2>/dev/null

			# add it to the counter
			counter=$(( $counter + 1 ))

			# status update
			printf "added!\n \n"
		done

		# done with loop so let user konw
		echo "$counter IPs were added to blocked_ips table"
		echo "done and exiting..."
		exit 0;;
	[Nn]* ) 
		# no so exit script
		echo "exiting script..."
		exit 0;;
esac


# exit just in case
exit 0