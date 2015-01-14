quicksite.sh
Quickly spin up a Drupal/CiviCRM site from the bash command line.

============================
INSTALLATION:
1. Copy config.sh.dist to config.sh
2. Edit config.sh according to comments in that file.
   (Variables named in this README file are defined in confg.sh)

============================
USAGE:
bash quicksites.sh BASENAME DRUPAL_VERSION CIVICRM_VERSION
  BASENAME: Used in a few ways:
    name of directory under $root_directory to use as document root;
    used in the site URL as \${basename}.${basedomain} (see "makevhost", below)
    used in naming the site Drupal and CiviCRM directories as
      localhost_${basename}_drupal and localhost_${basename}_civicrm;

  DRUPAL_VERSION: Drupal version string suitable for use as `drush dl drupal $DRUPAL_VERSION`
  CIVICRM_VERSION: Complete CiviCRM version string, e.g., 4.2.19

The user with uid=1 on the created site will have username="admin" and password="admin".

Example: bash quicksites.sh foo 7.x 4.2.19
This will create a site using the latest version of Drupal 7 with CiviCRM 4.2.19,
having a document root at $root_directory/foo/, and (if makevhost is installed --
see below) available at "http://foo.${basedomain}".

============================
makevhost
After usage, you'll need to take your own steps to ensure 1) existence of
a virtualhost for your local environment, and 2) routing of the site URL
to your local machine. If the command "makevhost" is found in your path,
quicksite.sh will attempt to take care of these two tasks automatically,
by calling `makevhost "${basename}.${basedomain}" "$root_directory/$basename" 
A `makevhost` script is included in this repo, under makevhost/, designed 
to work in Ubuntu environments.  You may modify this script as needed and 
add it to your execution path.  See makevhost/README.txt for more info.

============================
REQUIREMENTS:
  drush
  curl
  All Drupal and CiviCRM requirements, of course.


