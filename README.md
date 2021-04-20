# trollr
Pantheon Drupal site blocked IPs comparision and additions

## overview
- takes a list of known bad actor IPs
- pulls current list of IPs from Drupal table blocked_ips
- compares the list and manually adds to the table via terminus drush
- gathers 200 IP address then adds in a batch for performance

## requirements
- terminus (with active session from `terminus auth:login`)
- drush


## usage
- Download or clone the repository to your local machine
- Add any additional IPs you would like to ban to `trolls.dat`
- Make the trollr-drupal.sh script executable by running
  - `chmod 775 trollr-drupal.sh`
- Run the script
  - `./trollr-drupal.sh`
  - Then follow the prompt options to enter which site you'd like to run it on
- Or run the script by passing the sitename with the -s flag
  - `./trollr-drupal.sh -s SITENAME`
  - The follow the prompt options to compete the script