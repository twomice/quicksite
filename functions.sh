# Compare two version strings using a given 
# comparison operator.
#
# parameter: VERSION1: a dot-delimited 
#  CiviCRM version string. E.g., 3.1.2, 4.2.19
# parameter: OP: Any one of the following comparison
#   operators:
#     =   (equal to)
#     ==  (equal to)
#     >   (greater than)
#     >=  (greater than or equal to)
#     <   (less than)
#     <=  (less than or equal to)
# parameter: VERSION2: another dot-delimited
#  CiviCRM version string. 
#
# exit code: 0 if the expression "$VERSION1 $OP $VERSION2" 
#   is true; otherwise 1.
#
# Based on code found at http://stackoverflow.com/a/4025065.
version_compare() {
  # Comparison result.
  RESULT=""

  # Prepare to split on dots.
  local IFS=.

  # Initialize local variables.
  local i VERSION1=($1) OP=($2) VERSION2=($3)

  # If versions are identical, return 1.
  if [[ $1 == $3 ]]; then
    RESULT=1
  else
  

    # Loop through parts in version1 and fill 
    # empty trailing fields with zeros, so that
    # VERSION1 and VERSION2 have the same number
    # of fields.
    for ((i=${#VERSION1[@]}; i<${#VERSION2[@]}; i++)); do
      VERSION1[i]=0
    done
  
    # Loop through parts in version1.
    for ((i=0; i<${#VERSION1[@]}; i++)); do
      # Fill empty fields in version2 with zeros.
      if [[ -z ${VERSION2[i]} ]]; then
        VERSION2[i]=0
      fi
#echo
#echo "v1 part $i: ${VERSION1[i]}"
#echo "v2 part $i: ${VERSION2[i]}"

      # If the version1 part is greater than its corresponding
      # version2 part, return 0.
      if [[ 10#${VERSION1[i]} > 10#${VERSION2[i]} ]]; then
        RESULT=2
        break;
      # If the version1 part is less than its corresponding
      # version2 part, return 1.
      elif [[ 10#${VERSION1[i]} < 10#${VERSION2[i]} ]]; then
        RESULT=0
        break;
      fi
    done
    # If we're still here, the versions are effectively
    # equivalent, though not literally identical (e.g.,
    # 1.1.1 and 1.01.1). Return 1.
    if [[ -z $RESULT ]]; then
      RESULT=1
    fi
  fi
#echo "args: $1 $2 $3: $RESULT"
#echo "vars: $VERSION1 $OP $VERSION2: $RESULT"
#echo "result: $RESULT; op $OP"

  case $OP in
    '='|'==') 
      if [[ "$RESULT" == "1" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    '>') 
      if [[ "$RESULT" == "2" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    '<') 
      if [[ "$RESULT" == "0" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    '<=') 
      if [[ "$RESULT" -le "1" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    '>=') 
      if [[ "$RESULT" -ge "1" ]]; then
        return 0
      else
        return 1
      fi
      ;;
  esac
}


do_delete() {
  rm -rf $root_directory/$basename
  mysql --user=$mysql_root_user_name --password=$mysql_root_user_pass -e "DROP DATABASE IF EXISTS localhost_${basename}_drupal"
  mysql --user=$mysql_root_user_name --password=$mysql_root_user_pass -e "DROP DATABASE IF EXISTS localhost_${basename}_civicrm"
}

check_exists() {
  if [[ -e "$root_directory/$basename" ]]; then
    return 1;
  fi

  line_count = $(mysql --user=$mysql_root_user_name --password=$mysql_root_user_pass -e "show databases like 'localhost_${basename}_drupal'" | wc -l);
  if [[ "$line_count" > "0" ]]; then 
    return 1;
  fi

  line_count = $(mysql --user=$mysql_root_user_name --password=$mysql_root_user_pass -e "show databases like 'localhost_${basename}_civicrm'" | wc -l);
  if [[ "$line_count" > "0" ]]; then 
    return 1;
  fi
}

download_and_extract_tarball() {
  civicrm_version=$1
  extract_directory=$2

  if [[ "$#" != "2" ]]; then
    echo "ERROR: Missing required arguments"
    echo "Usage: $FUNCNAME civicrm_version extract_directory"
    return 1
  fi

  max_download_attempts=2
  download_attempts=0
  download_successful=0
  
  tarball=$(print_civicrm_tarball_name $civicrm_version $drupal_major_version)

  while [[ "$download_attempts" < "$max_download_attempts" && "$download_successful" == "0" ]]; do
    cd ${mydir}/downloads
    wget -nc http://sourceforge.net/projects/civicrm/files/civicrm-stable/${civicrm_version}/${tarball}/download -O ${tarball}
    # Increment download_attempts counter.
    download_attempts=$((download_attempts+1))

    cp ${tarball} $extract_directory
    cd $extract_directory
    echo "In $extract_directory: tar xfz ${tarball}"
    tar xfz ${tarball}
    result=$?
    if [[ "$result" == "0" ]]; then
      download_successful=1
    else
      rm -f ${mydir}/downloads/${tarball}
    fi
  done
  if [[ "$download_successful" == "0" ]]; then
    echo "ERROR: Tarball ${tarball} could not download successfully"
    echo "after ${download_attempts} attempts. Exiting."
    exit 1
  fi
}

# Get the current major Drupal version (e.g., 6, 7, 8)
print_drupal_version() {
  smart_drush status | grep "Drupal version" | awk '{ print $NF }' | awk -F '.' '{ print $1 }'
}

smart_drush() {
  pushd "${root_dir}/${basename}" > /dev/null
  drush "$@"
  popd > /dev/null
}

print_civicrm_tarball_name() {
  civicrm_version=$1
  drupal_major_version=$2

  # Use "6" only for Drupal 6 and civicrm >= 4.1.
  if version_compare "$civicrm_version" ">=" "4.1"; then
    is_over_41=1
  fi 
  
  if [[ "$is_over_41" == "1" && "$drupal_major_version" == "6" ]]; then
    drupal_6_string="6"
  else
    drupal_6_string=""
  fi
  echo "civicrm-${civicrm_version}-drupal${drupal_6_string}.tar.gz"
}
