NatLang
=======

Copyright (C) 2011-2013 Jerry Chen <mailto:onlyuser@gmail.com>

About
-----

NatLang is a parser framework for natural language processing.

A Motivating Example
--------------------

input:
<pre>
the quick brown fox jumps over the lazy dog
</pre>

output:

![picture alt](https://sites.google.com/site/onlyuser/files/ast_fox.png "the quick brown fox jumps over the lazy dog")

Usage
-----

<pre>
./app/bin/NatLang -e "the quick brown fox jumps over the lazy dog" -d | dot -Tpng -oast_fox.png
</pre>

Requirements
------------

Unix tools and 3rd party components (accessible from $PATH):

    gcc (with -std=c++0x support), flex, bison, valgrind, cppcheck, doxygen, graphviz, ticpp

**Environment variables:**

* $INCLUDE_PATH_EXTERN -- where "ticpp/ticpp.h" resides
* $LIB_PATH_EXTERN     -- where "libticppd.a" resides

Make targets
------------

<table>
    <tr><th> target </th><th> action                                                </th></tr>
    <tr><td> all    </td><td> make binaries                                         </td></tr>
    <tr><td> test   </td><td> all + run tests                                       </td></tr>
    <tr><td> pure   </td><td> test + use valgrind to check for memory leaks         </td></tr>
    <tr><td> dot    </td><td> test + generate .png graph for tests                  </td></tr>
    <tr><td> lint   </td><td> use cppcheck to perform static analysis on .cpp files </td></tr>
    <tr><td> doc    </td><td> use doxygen to generate documentation                 </td></tr>
    <tr><td> xml    </td><td> test + generate .xml for tests                        </td></tr>
    <tr><td> import </td><td> test + use ticpp to serialize-to/deserialize-from xml </td></tr>
    <tr><td> clean  </td><td> remove all intermediate files                         </td></tr>
</table>

References
----------

<dl>
    <dt>"Part-of-speech tagging"</dt>
    <dd>http://en.wikipedia.org/wiki/Part-of-speech_tagging</dd>
</dl>

Keywords
--------

    Lex, Yacc, Flex, Bison, Parser, Reentrant
