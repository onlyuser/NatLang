#!/bin/bash

# NatLang
# -- An English parser with an extensible grammar
# Copyright (C) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

show_help()
{
    echo -e "Usage: `basename $0` <EXEC> <INPUT_MODE={xml|file|stin|arg}> <INPUT_FILE> \c"
    echo "<OUTPUT_FILE_TYPE={bmp|jpg|gif|png|lisp|xml}> <OUTPUT_FILE_STEM>"
}

if [ $# -ne 5 ]; then
    echo "fail! -- expect 5 arguments! ==> $@"
    show_help
    exit 1
fi

EXEC=$1
INPUT_MODE=$2
INPUT_FILE=$3
OUTPUT_FILE_TYPE=$4
OUTPUT_FILE_STEM=$5
OUTPUT_FILE="${OUTPUT_FILE_STEM}.$OUTPUT_FILE_TYPE"

if [ ! -f $INPUT_FILE ]; then
    echo "fail! -- INPUT_FILE not found! ==> $INPUT_FILE"
    exit 1
fi

case $OUTPUT_FILE_TYPE in
    "bmp"|"jpg"|"gif"|"png") EXEC_FLAGS="--dot" ;;
    "lisp"|"xml")            EXEC_FLAGS="--$OUTPUT_FILE_TYPE" ;;
    *)
        echo "fail! -- invalid output file type"
        exit 1
        ;;
esac

EMIT_SH=`dirname $0`/"emit.sh"
$EMIT_SH $EXEC $EXEC_FLAGS $INPUT_MODE $INPUT_FILE $OUTPUT_FILE_STEM

if [ $EXEC_FLAGS == "--dot" ]; then
    DOT_TOOL="dot"
    DOT_FLAGS="-T$OUTPUT_FILE_TYPE"
    $DOT_TOOL $DOT_FLAGS -o $OUTPUT_FILE $OUTPUT_FILE_STEM
elif [ $EXEC_FLAGS == "--xml" ]; then
    mv $OUTPUT_FILE_STEM $OUTPUT_FILE
fi

echo "success!"
