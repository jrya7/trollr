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
# - gathers 200 IP address then adds in a batch for performance
#





###
### files & variables ###
###
# file for the list of IPs that are known bad actors
fileTrolls=`cat trolls.dat`

# counter for how many got banned
counterBanned=0

# counter for the loop
counterLoop=0

# var to hold the 200 ips
hundoIPs=""

# var to start the sitename
SITENAME=""


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
		echo "you are not authenticated with terminus, please login with terminus auth:login and re-run the script"
		exit 0
	# user login found so make sure its correct user
	else
		echo "logged in as $response"
	fi
}



###
### flag handles
###
while getopts ":s:" opt; do
  case $opt in
    s)
		# got a flag so set to the variable
		SITENAME=$OPTARG
		;;
    \?)
		echo "unsupported flag: -$OPTARG" >&2
		exit 1
		;;
    :)
		echo "flag -$OPTARG requires an argument" >&2
		exit 1
		;;
  esac
done



###
### main ###
###
# check for logged in user
terminus_auth_check

# check if the sitename has already been set or not
if [ -z "${SITENAME}" ]; then
	# grab the sites
	echo "grabbing site list..."
	terminus site:list --fields="name"

	# set the site to use
	read -p 'type in site name and press [Enter] to start trollr on: ' SITENAME
fi

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

# check if there are IPs to add
if [ "$numDiff" != 0 ]; then
	# display and ask to continue
	read  -p "$numDiff number of new IPs to block, continue? [y/n] " yn
	case $yn in
		[Yy]* ) 
			# before looping inform user
			printf "\n"
			printf "starting loop, this may take a while depending on the number of additions...\n"

			# yes so loop thru list and add to table
			for banIP in $diffIPs; do
				# if the counter is 200
				if [ "$counterLoop" == 199 ]; then
					# add it to the counter
					counter=$(( $counter + 1 ))

					# have 200 so reset counter
					counterLoop=0

					# add in the IPs
					hundoIPs="$hundoIPs , ('$banIP')"

					# quick echo
					printf "%s" "adding entries..."

					# terminus call
					# for adding single entries
					# echo terminus drush ${SITENAME}.live -- sql-query 'INSERT IGNORE INTO blocked_ips SET ip = "'$hundoIPs'"' &>/dev/null
					# for adding multiple entries
					terminus drush ${SITENAME}.live -- sql-query "INSERT IGNORE INTO blocked_ips (ip) VALUES $hundoIPs" &>/dev/null

					# status update
					printf "success! $counter IPs added\n"

					# reset the var to hold the 200 IPs
					hundoIPs=""
				# not to 200 IPs yet
				else
					# add it to the counter
					counter=$(( $counter + 1 ))

					# not 200 yet so bump counter 
					counterLoop=$(( $counterLoop + 1 ))

					# check if there has been an IP added or not
					if [ -z "${hundoIPs}" ]; then
						# its blank so just set
						hundoIPs="('$banIP')"

					# it has an IP in it
					else
						# add to end of var
						hundoIPs="$hundoIPs , ('$banIP')"
					fi				
				fi
			done

			# need to check insert incase the counter wasnt reached
			if (( "$counterLoop" < 199 )); then
				# quick status message
				printf "%s" "loop done, inserting the leftovers..."

				# for adding multiple entries
				terminus drush ${SITENAME}.live -- sql-query "INSERT IGNORE INTO blocked_ips (ip) VALUES $hundoIPs" &>/dev/null

				# status update
				printf "success!\n\n"
			fi


			# done with loop so let user konw
			echo "$counter IPs were added to blocked_ips table"
			echo "done and exiting..."
			exit 0;;
		[Nn]* ) 
			# no so exit script
			echo "exiting script..."
			exit 0;;
	esac
# no ips to add
else
	# no so exit script
	echo "no IPs to add, exiting script..."
	exit 0
fi


# exit just in case
exit 0