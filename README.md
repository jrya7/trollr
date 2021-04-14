# trollr
Pantheon Drupal site blocked IPs comparision and additions

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
- Follow the prompt options to enter which site you'd like to run it on