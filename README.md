[![Build Status](https://secure.travis-ci.org/onlyuser/NatLang.png)](http://travis-ci.org/onlyuser/NatLang)

NatLang
=======

Copyright (C) 2011-2013 Jerry Chen <mailto:onlyuser@gmail.com>

About
-----

NatLang is a parser framework for natural language processing.
It uses WordNet and a Yacc grammar to generate all possible interpretations of a sentence.

It works as follows:

1. The user inputs a sentence.
2. WordNet identifies one or more POS identities for each word in the sentence.
3. All POS configurations of the sentence are evaluated using the Yacc-generated parser.
4. A parse tree is generated for each successful parse.

For example:

The sentence "eats shoots and leaves" has four interpretations depending on the POS of "shoots" and "leaves".

<pre>
eats  shoots and leaves
 |     |      |   |
(V)---(V)----(C)-(V)
   \        /   \
    *-(N)--*     (N)

Path #1: {V V C V}
Path #2: {V V C N}
Path #3: {V N C V}
Path #4: {V N C N}
</pre>

The sentence "flying saucers are dangerous" has two interpretations depending on the POS of "flying".

<pre>
flying saucers are   dangerous
 |      |       |     |
(Adj)--(N)-----(Aux)-(Adj)
      /
(V)--*

Path #1: {Adj N Aux Adj}
Path #2: {V   N Aux Adj}
</pre>

TODO: Additional analyses passes can be applied to the generated trees for further processing.

A Motivating Example
--------------------

input:
<pre>
the quick brown fox jumps over the lazy dog
</pre>

output:

<pre>
                         S'
                         |
                         |
                         |
                         S
                         |
          |---------------------------------------|
          |                        |              |
          NP                      VP              $
          |                        |              |
  |---------|           |-------------|           |
  |         |           |             |           |
 Det        N           V            AP           .
  |         |           |             |
  |       |-------|     |             |
  |       |       |     |             |
 the     A'      Noun Verb          PP_VP
          |       |     |             |
       |-----|    |     |      |----------|
       |     |    |     |      |          |
       A     A   fox  jumps Prep_VP      NP
       |     |                 |          |
       |     |               |--     |------|
       |     |               |       |      |
      Adj   Adj             over    Det     N
       |     |                       |      |
       |     |                       |   |----|
       |     |                       |   |    |
     quick brown                    the  A'  Noun
                                         |    |
                                         |    |
                                         |    |
                                         A   dog
                                         |
                                         |
                                         |
                                        Adj
                                         |
                                         |
                                         |
                                        lazy
</pre>

Usage
-----

<pre>
./app/bin/NatLang -e "the quick brown fox jumps over the lazy dog" -d | dot -Tpng -oast_fox.png
</pre>

Requirements
------------

Unix tools and 3rd party components (accessible from $PATH):

    gcc (with -std=c++0x support), flex, bison, wordnet, valgrind, cppcheck, doxygen, graphviz, ticpp

**Environment variables:**

* $INCLUDE_PATH_EXTERN -- where "ticpp/ticpp.h" resides
* $LIB_PATH_EXTERN     -- where "libticppd.a" resides

Limitations
-----------

* Only English is supported
* WordNet doesn't provide tense information for POS lookup, so hard-coded POS identities are used for some common words
* No attempt is made to prune the parse trees
* No attempt is made to parallelize the POS assignment evaluation
* The Yacc grammar is hand-crafted without a corpus to justify its rules

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

    <dt>"Princeton WordNet"</dt>
    <dd>http://wordnet.princeton.edu/</dd>

    <dt>"Syntactic Theory: A Unified Approach"</dt>
    <dd>ISBN: 0340706104</dd>
</dl>

Keywords
--------

    Lex, Yacc, Flex, Bison, NLP, Natural Language Processing, WordNet, Part-of-Speech Tagging, Yacc Grammar for English, Linguistics, Phrase Structure Grammar, X-bar Theory, POS, PSG, BNF, CFG, GLR
