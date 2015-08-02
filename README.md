[![Build Status](https://secure.travis-ci.org/onlyuser/NatLang.png)](http://travis-ci.org/onlyuser/NatLang)

NatLang
=======

Copyright (C) 2011-2015 Jerry Chen <mailto:onlyuser@gmail.com>

About
-----

NatLang is an English parser with an extensible grammar.
It generates abstract syntax trees for all possible interpretations of an English sentence.
The grammar is fully customizable. No training data is involved.

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

![picture alt](https://sites.google.com/site/onlyuser/files/ast_fox.png "ast_fox")

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

* Only supports English.
* Only supports present, present progressive, or past tense statements in the active voice (for now).
* WordNet doesn't provide POS look-up for inflected verb forms and mechanical words such as prepositions, leading to a reliance on hard-coded POS definitions in the lexer.
* Brute force algorithm tries all possibilities. This is slow for long sentences.
* BNF rules are suitable for specifying constituent-based phrase structure grammars, but a poor fit for expressing non-local dependencies.

Strategy to Resolving Grammar Ambiguity
---------------------------------------

1. Identify lexer terminal with ambiguous meaning.
2. Identify parser rules that use the lexer terminals with ambiguous meaning, and assign each use case a different lexer terminal ID.
3. Take advantage of stateful lexing to return different lexer terminal IDs when recognizing the same lexer terminal regex.
4. Carefully tune grammar such that each rule has a unique FIRST(1) look-ahead in each use case.

Make Targets
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

    <dt>"Enju - A fast, accurate, and deep parser for English"</dt>
    <dd>http://www.nactem.ac.uk/enju/</dd>
</dl>

Keywords
--------

    Lex, Yacc, Flex, Bison, NLP, Natural Language Processing, WordNet, Part-of-Speech Tagging, Yacc Grammar for English, English parser, parsing English, Linguistics, Phrase Structure Grammar, X-bar Theory, POS, PSG, BNF, CFG, GLR
