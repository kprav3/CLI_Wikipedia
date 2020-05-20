#!/bin/bash --
#
# Shell script to query the Wikipedia.
#
VERSION=0.14

set -e

#The script uses text-browser to query and render Wikipedia articles. 
#The output is printed on standard out.
#Help function that displays the different options of query avaible 

function display_help(){ 
cat << EOF
    -p  display using a pager   
    -o  open Wikipedia article  
    -h  display help
    -r  open Random Page
EOF
}
function getVersion(){
cat <<EOF
  $(basename "${0}") Version: ${VERSION}
EOF
}
function errorExit(){
  echo "$*" >&2
  exit 3
}
function uri_decode(){
  echo -e "$*" |perl -MURI::Escape -lne 's/ /_/g;s/"//g;print uri_escape($_);'
}

#Our localized version is English by default
function localize(){ 
LOCAL=$(echo ${LOCAL:="en"})
if [ "${LOCAL}" = "en" -o "${LOCAL}" = "simple" ]; then
  MARKER='^\s*Categories:\|^\s*Category:'
  MARKER2='edit'
  RANDOMP='Special:Random'
else
  MARKER='\(Views\|References\|Visible links\)'
  RANDOMP='Special:Random'
fi
}

#Strip everything from marker to end - tcpdump
function stripOutput(){ 
SED='sed -e "s|\^\?\\[[0-9]*\\]||g" -e "s|\\[IMG\\]||g" -e "/${MARKER}/,$ D" '
if [ -n "${MARKER2}" ]; then
  echo "`cat`"| eval ${SED} -e '"s#\[${MARKER2}\]##g"'
else
  echo "`cat`"| eval ${SED}
fi
}

#function to open url
function openurl(){ 
  "${BROWSER}" "${URL}"
}

#function to print certain sections of the Wikipedia article
function print_sections() { 
  TMPFILE="/tmp/wiki-sections_$$.html"
  Command="curl -s -L ${URL} | grep '\(</\?html\)\|\(</\?body\)\|\(<h[12]\)' |
    sed -e 's/^.*<h2/<h2/' > $TMPFILE && w3m -dump $TMPFILE | stripOutput && rm $TMPFILE"
  eval ${Command}
}

function print_section_detail() { 
  TMPFILE="/tmp/wiki-section_$$.html"
  Command="curl -s -L ${URL} |
    sed -n -e '/\(<\/\?html\)\|\(<\/\?body\)\|\(<h1\)/p' -e \"/^.*<h2.*$*/,/^.*<\/h2.*>/p\" |
    sed -e 's/^.*<h2/<h2/' > $TMPFILE && w3m -dump $TMPFILE | stripOutput"
  if [ "${COLOR}" = "true" ]; then
    eval "${Command} | colorize"
  else
    eval "${Command}"
  fi
  rm $TMPFILE
}

function getInfo(){ 
  getInfoCommand="${BROWSER} ${BROWSEROPTIONS} -dump ${URL} | stripOutput"
  if [ "${COLOR}" = "true" ]; then
    getInfoCommand="${getInfoCommand} | colorize"
  fi
  eval ${getInfoCommand}
}

# First read in the Run configuration File, if one is found 
if [ -r ~/.`basename $0`rc ]; then
  source ~/.`basename $0`rc
  ABROWSER=${BROWSER}
fi

# Process commandline parameters
# According to the command line inputs 
while getopts "oOpPr-help" ARGS
  do
  case ${ARGS} in
    o) USEBROWSER="true" ;;
    O) USEBROWSER="false" ;;
    p) PAGER="true" ;;
    P) PAGER="false" ;;
    r) RAND="true" ;;
    h) display_help; exit 0 ;;
    -help) display_help; exit 0 ;;
    *) display_help; exit 1 ;;
  esac
done

shift `expr ${OPTIND} - 1`

# Init some variables 
localize

# Setting Up some Variables, to determine, what actually to do
if [ -z "$1"  -a  -z "${RAND}" ]; then
  display_help
  exit 1;
fi

IGNCASE=$(echo ${IGNCASE:="false"})
PAGER=$(echo ${PAGER:="false"})
OPENURL=$(echo ${OPENURL:="false"})
RAND=$(echo ${RAND:="false"})

if [ "$PAGER" = "true" ]; then
  { PAGER=$(which less) || PAGER=$(which more) ; } || errorExit "No Pager found!" ;
fi

PAGER=$(echo ${PAGER/less/less -Rr})
COLOR=$(echo ${COLOR:="false"})

if [ "$COLOR" = "true" -a -z "${PATT}" ]; then
  PATT="$*"
fi

if [ "$OPENURL" = "true" ]; then
  URL="$*"
fi

# Check for Alternative Browser
if [ -n "${ABROWSER}" ]; then
  BROWSER=$(which "${ABROWSER}") ||  errorExit "${ABROWSER} not found"

elif [ -n "${BROWSER}" ]; then
  BROWSER=$(which "${BROWSER}") ||  errorExit "${BROWSER} not found"

else
  { BROWSER=$(which w3m) ||
    BROWSER=$(which elinks) ||
    BROWSER=$(which links2) ||
    BROWSER=$(which lynx) ||
    BROWSER=$(which links.main) ||
    BROWSER=$(which links) ; } || errorExit "No Browser found"
fi

# Open page in Browser
USEBROWSER=$(echo ${USEBROWSER:="false"})

# Output only a summary
SHORT=$(echo ${SHORT:="false"})

# custom Section
SECTION=$(echo ${SECTION:=""})

# Output only the URL
OUTPUTURL=$(echo ${OUTPUTURL:="false"})

# Now we do some input sanitizing.
ARGUMENT="$(uri_decode "$*")"

LOCAL="$(echo "${LOCAL}"|tr '[:upper:]' '[:lower:]')"

# Random page for -r option
if [ "${RAND}" = "true" ]; then
  ARGUMENT="$(uri_decode "${RANDOMP}")"
fi

if [ -z "${URL}" ]; then
  URL="http://${LOCAL}.wikipedia.org/wiki/${ARGUMENT}"
fi

if [ -n "${WURL}" ]; then
  WURL="$(echo "${WURL%%/}")"
  case "${WURL}" in
    http://*) URL="${WURL}"/wiki/"${ARGUMENT}" ;;
    *) URL="http://""${WURL}"/wiki/"${ARGUMENT}" ;;
  esac;
  # unset $LOCAL to force using an english-locale
  # this is used to strip the tags [edit], eg.
  LOCAL="en"
fi

# Debug mod
if [ "${DEBUG:=false}" = "true" ]; then 
  printf "PAGER: $PAGER Browser: $BROWSER Local: $LOCAL COLOR: $COLOR PATT: $PATT IGNCASE: $IGNCASE URL: $URL Summary: $SHORT\n"
fi

# Depending on some Variables, we do some different things here 
if [ "${USEBROWSER}" = "true" ]; then
  openurl
  exit 0;
fi

if [ "${SHORT}" = "true" ]; then
  summary
  exit 0;
fi

if [ "${SECTION}" = "show" ]; then
  print_sections
  exit 0;
elif [ -n "${SECTION}" ]; then
  print_section_detail ${SECTION}
  exit 0;
fi

if [ "${OUTPUTURL}" = "true" ]; then
  if [ "${COLOR}" = "false" ]; then
    echo
 "${URL}"
    echo "${BROWSER}" "${BROWSEROPTIONS}" -dump "${URL}"
  else
    echo -e "\033[0;34m${URL}\033[0m"
  fi
  exit 0;
fi

if [ "$PAGER" != "false" ]; then
  getInfo | ${PAGER}
else
  getInfo
fi
