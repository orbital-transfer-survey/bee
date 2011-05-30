#!/bin/bash
#
# bee-query - query bee metadata
# Copyright (C) 2009-2010 
#       Tobias Dreyer <dreyer@molgen.mpg.de>
#       Marius Tolzmann <tolzmann@molgen.mpg.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

if [ -z ${BEE_VERSION} ] ; then
    echo >&2 "BEE-ERROR: please call $0 from bee .."
    exit 1
fi

VERSION=${BEE_VERSION}

##### usage ###################################################################
usage() {
    echo "bee-query v${VERSION} 2009-2010"
    echo ""
    echo "  by Tobias Dreyer and Marius Tolzmann <{dreyer,tolzmann}@molgen.mpg.de>"
    echo ""
    echo " Usage: $0 <file> [ <file> .. ]"
}

query() {
    list=$@
    
    for f in "${list[@]}" ; do
        # check if $f is pkg, list related files
        # otherwise list pkg
        base=$(basename $f)
        if [ -d "${BEE_METADIR}/${base}" ] ; then
            eval $(beeversion $base)
            get_files "${PKGALLPKG}"
        else
            get_pkgs ${f}
        fi
    done
}

get_files() {
    pkg=${1}
    
    for s in "" "${BEE_METADIR}" ; do 
        ff="${s}/${pkg}/FILES"
        if [ -e "${ff}" ] ; then
            for line in $(cat ${ff}) ; do
                beefind2filename $line
            done
        fi
    done
}

get_pkgs() {
    f=$1
    
    for i in ${BEE_METADIR}/* ; do
        if egrep -q "file=.*${f}" ${i}/FILES ; then
            echo $(basename ${i})
            for line in $(egrep "file=.*${f}" ${i}/FILES) ; do
                echo "  $(beefind2filename $line)"
            done
        fi
    done
}

beefind2filename() {
    line=$1
    
    OLDIFS=${IFS}
    IFS=":"
    eval $line
    echo $file
    unset md5 mode nlink uid gid size mtime file
    IFS=${OLDIFS}
}



###############################################################################
###############################################################################
###############################################################################

options=$(getopt -n bee-query \
                 -o h \
                 --long help \
                 -- "$@")
if [ $? != 0 ] ; then
  usage
  exit 1
fi
eval set -- "${options}"

while true ; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    *)
      shift
      if [ -z ${1} ] ; then
           usage
           exit 1
      fi
      query ${@}
      exit 0;
      ;;
  esac
done
