#!/bin/bash

# This will be a util script
# to check that a cron should actually execute


shout() { echo "$0: $*" >&2; }
barf() { shout "$*"; exit 111; }
safe() { "$@" || barf "cannot $*"; }

zone="active.advance.ly"

facter_data="/etc/server_facts/server_facts.txt"


usage(){
  safe echo "[ -v verbose] [ -n name of host ] "
}

verbose(){

  set -xv
}


if [ $# -ne 0 ]; then
  while getopts vn:h opt; do
    case $opt in
      v) verbose
        ;;
      n) export fqndall="$OPTARG.${zone}"
        ;;
      h) usage  && exit 111
        ;;

      *) usage && exit 111
        ;;
    esac
  done
  shift $((OPTIND-1))
fi



if [ -z ${fqdnall}]; then
  # do variable dance to set proper hostname
  for i in server_stack server_tier server_substack; do
    export $i=`grep $i ${facter_data}| awk '{print $2}'`
  done


  # declare empty array to make the fqdn dance smart
  declare -a fqdnarray

  # loop through the variables and only add non null elements to array
  for n in ${server_stack} ${server_tier} ${server_substack}; do
    [ -z $n ] || fqdnarray=("${fqdnarray[@]}" "$n")
  done


  # format the domain name
  enfqdn=$(/usr/bin/printf "%s-" "${fqdnarray[@]}")
  fqdnall="${enfqdn%-}.${zone}"
fi

dig_command="`dig +short TXT ${fqdnall} | tr -d '"'`"

if [[ `echo -n ${dig_command}` == "true" ]]; then
  exit 0
else
  exit 1
fi
