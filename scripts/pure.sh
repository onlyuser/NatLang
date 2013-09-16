#!/bin/bash

# NatLang
# -- A parser framework for natural language processing
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
    echo "Usage: `basename $0` <EXEC> <INPUT_MODE={xml|file|stdin|arg}> <INPUT_FILE> <GOLD_KEYWORD> <OUTPUT_FILE_STEM>"
}

if [ $# -ne 5 ]; then
    echo "fail! -- expect 5 arguments! ==> $@"
    show_help
    exit 1
fi

TEMP_FILE=`mktemp`
trap "rm $TEMP_FILE" EXIT

EXEC=$1
INPUT_MODE=$2
INPUT_FILE=$3
GOLD_KEYWORD=$4
OUTPUT_FILE_STEM=$5
PASS_FILE=${OUTPUT_FILE_STEM}.pass
FAIL_FILE=${OUTPUT_FILE_STEM}.fail

if [ ! -f $INPUT_FILE ]; then
    echo "fail! -- INPUT_FILE not found! ==> $INPUT_FILE"
    exit 1
fi

if [ ! -f $GOLD_FILE ]; then
    echo "fail! -- GOLD_FILE not found! ==> $GOLD_FILE"
    exit 1
fi

PURE_TOOL="valgrind"
PURE_FLAGS="--leak-check=full"
EXEC_FLAGS="--lisp"
case $INPUT_MODE in
    "file")
        $PURE_TOOL $PURE_FLAGS $EXEC $EXEC_FLAGS --in-file $INPUT_FILE 2> $TEMP_FILE
        ;;
    "stdin")
        cat $INPUT_FILE | $PURE_TOOL $PURE_FLAGS $EXEC $EXEC_FLAGS 2> $TEMP_FILE
        ;;
    "arg")
        $PURE_TOOL $PURE_FLAGS $EXEC $EXEC_FLAGS --expr `cat $INPUT_FILE` 2> $TEMP_FILE
        ;;
    *)
        echo "fail! -- invalid input mode"
        exit 1
        ;;
esac

if [ -z "`grep \"$GOLD_KEYWORD\" $TEMP_FILE`" ]; then
    echo "fail!"
    cp $TEMP_FILE $FAIL_FILE # TEMP_FILE already trapped on exit!
    exit 1
fi

echo "success!" | tee $PASS_FILE
