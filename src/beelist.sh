#!/bin/bash
#
# bee-list 2009-2011
#   by Marius Tolzmann and Tobias Dreyer {tolzmann,dreyer}@molgen.mpg.de
#     Max Planck Institute for Molecular Gentics Berlin Dahlem
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#

if [ -z ${BEE_VERSION} ] ; then
    echo >&2 "BEE-ERROR: please call $0 from bee .."
    exit 1
fi

VERSION=${BEE_VERSION}

#
# BUGS TO FIX/FEATURES TO ADD: 
#   - lists are alpha-num sorted and not as pkg-versions ..
#   - check for grep -P support and use it..

ARCH=$(arch)

#
# print usage information
#
usage() {
    cat <<-EOF
	bee-list v${VERSION} 2009-2011
	  by Marius Tolzmann and Tobias Dreyer {tolzmann,dreyer}@molgen.mpg.de
	     Max Planck Institute for Molecular Gentics Berlin Dahlem
	
	usage: $0 [action] [pattern list]
	
	available actions:
	    -i | --installed (default) list installed pkgs matching pattern list
	    -a | --available           list available pkgs matching pattern list
	
	EOF
}

#
# lists installed packages 
#   RETURNS a sorted list of installed packages
#
list_installed() {
    find ${BEE_METADIR} -mindepth 1 -maxdepth 1 -printf "%f\n" \
        | sort
}

#
# lists available packages
#   RETURNS a sorted list of packages available in ${BEE_REPOSITORY_PKGDIR}
#   or in any directory in ${BEE_REPOSITORY_PKGPATH}
#
list_available() {
    # preapre for repository pathes..
    : ${BEE_REPOSITORY_PKGPATH:=${BEE_REPOSITORY_PKGDIR}}
    
    # replace all ':' with ' ' in BEE_REPOSITORY_PKGPATH
    path=${BEE_REPOSITORY_PKGPATH//:/ }
    
    find ${path} -mindepth 1 -maxdepth 1 -printf "%f\n" \
        | sed -e "s@\.iee\.tar\..*\$@@" \
              -e "s@\.bee\.tar\..*\$@@" \
        | sort 
}

#
# list bee packages
#   ARGUMENTS are $mode (installed|available) and a list of $patterns
#   RETURNS a list of $mode packages matching all given $patterns
#
list_beepackages() {
    mode=${1}
    shift
    
    # if more then one pattern is given all pattern have to match (AND)
    thegrep=""
    for p in ${@} ; do
        thegrep="${thegrep} | grep -i -E -e '${p}' "
    done
    
    if [ "${mode}" = "available" ] ; then
        list_cmd="list_available"
    else
        list_cmd="list_installed"
    fi
    
    # execute the search and display results..
    eval ${list_cmd} ${thegrep}
}


################################################################################
################################################################################
################################################################################

options=$(getopt -n bee-list \
                 -o aih \
                 --long available \
                 --long installed \
		 --long exact \
                 --long help \
                 --long debug \
                 -- "$@")
if [ $? != 0 ] ; then
  usage
  exit 1
fi
eval set -- "${options}"

filter=""

OPT_EXACT="no"

DEBUG=":"
while true ; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -a|--available)
            shift
            filter="available"
            ;;
        -i|--installed)
            shift
            filter="installed"
            ;;
        --exact)
            shift
            OPT_EXACT="yes"
            ;;
        --debug)
            shift
            DEBUG="echo"
            ;;
        --)
            shift
            break
            ;;
    esac
done


if [ "${OPT_EXACT}" = "yes" ] ; then
    if [ ! -z ${2} ] ; then
        echo >&2 "argument error: --exact only takes one package at a time .."
        exit 1
    fi

    for p in $(list_beepackages "${filter}" ${1}) ; do
        pname=$(beeversion --pkgfullname "${p}")
        pfull=$(beeversion --pkgfullpkg  "${p}")
        if [ "${1}" = "${pname}"  ] ; then
            echo "${p}"
        fi
        if [ "${1}" = "${pfull}"  ] ; then
            echo "${p}"
        fi
        if [ "${1}" = "${p}" ] ; then
            echo "${p}"
        fi
    done
    exit 0
fi

# mach et einfach.. (just do it)
list_beepackages "${filter}" ${@}

