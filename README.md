[![Build Status](https://secure.travis-ci.org/onlyuser/NatLang.png)](http://travis-ci.org/onlyuser/NatLang)

NatLang
=======

Copyright (C) 2011-2015 Jerry Chen <mailto:onlyuser@gmail.com>

About
-----

NatLang is an English parser with an extensible grammar.
It generates abstract syntax trees for all possible interpretations of an English sentence accepted by a grammar.
The algorithm is completely deterministic. No training data is required.

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

![picture alt](https://sites.google.com/site/onlyuser/files/ast_for_all.png "ast_for_all")
![picture alt](https://sites.google.com/site/onlyuser/files/ast_fox.png "ast_fox")

Strategy for Eliminating Grammar Ambiguity
------------------------------------------

English is a non-context-free language.
That means the same word used in different contexts can have different meanings.
But Yacc cannot interpret the same lexer terminal differently if it is represented using the same lexer terminal ID.
When this happens, it is necessary to split ambiguous terminals.

To do so:

1. Identify lexer terminal with ambiguous meaning.
2. Identify parser rules that use the lexer terminals with ambiguous meaning, and assign to each use case a different lexer terminal ID.
3. Take advantage of stateful lexing to return a different lexer terminal ID for the same lexer terminal.

For example:

The sentence "She and I run and he jumps and shouts." has three conjugations "and".

A possible parse tree may look like this:

<pre>
                (S)
                 |
         *-------*-------*
         |       |       |
        (S)      |      (S)
         |       |       |
     *---*---*   |   *---*----*
     |       |   |   |        |
    (NP)    (VP) |  (NP)     (VP)
     |       |   |   |        |
 *---*---*   |   |   |   *----*----*
 |   |   |   |   |   |   |     |   |
(N) (C) (N) (V) (C) (N) (V)   (C) (V)
 |   |   |   |   |   |   |     |   |
She and  I  run and  he jumps and shouts.
</pre>

Yacc chokes on this input due to the ambiguity of "and".

The solution is to split "and" into multiple lexer terminals, each representing a different abstraction level in the grammar.

* C_NP for noun-part level conjugations.
* C_VP for verb-part level conjugations.
* C_S for sentence level conjugations.

And to try all 27 permutations to see which ones work.

<pre>
She and    I  run and    he jumps and   shouts.
 |   |     |   |   |     |   |     |     |
(N) (C#1) (N) (V) (C#2) (N) (V)   (C#3) (V)

           C#1  C#2  C#3
            |    |    |
Path #1:  {C_NP C_NP C_NP} -- fail!
Path #2:  {C_NP C_NP C_VP} -- fail!
Path #3:  {C_NP C_NP C_S}  -- fail!
Path #4:  {C_NP C_VP C_NP} -- fail!
Path #5:  {C_NP C_VP C_VP} -- fail!
Path #6:  {C_NP C_VP C_S}  -- fail!
Path #7:  {C_NP C_S  C_NP} -- fail!
Path #8:  {C_NP C_S  C_VP} -- success!
...
Path #27: {C_S  C_S  C_S}  -- fail!
</pre>

Here, path #8's POS configuration results in a successful parse.

<pre>
She and     I  run and    he jumps and    shouts.
 |   |      |   |   |     |   |     |      |
(N) (C_NP) (N) (V) (C_S) (N) (V)   (C_VP) (V)
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

* Only supports English.
* Only supports present, present progressive, past tense, and past perfect tense statements in the active voice (for now).
* WordNet does not provide POS look-up for inflected verb forms and mechanical words such as prepositions, leading to a reliance on hard-coded POS definitions in the lexer for some words.
* A brute force algorithm tries all possibilities accepted by a grammar. This is slow for long sentences.
* BNF rules are suitable for specifying constituent-based phrase structure grammars, but are a poor fit for expressing non-local dependencies.

Known Issues
------------

* Fails to parse "he has quickly come here", whereas "he quickly comes here" works. Why?
* No passive voice statement support.
* No imperitive mood support.
* No question support.
* No conditional support.
* The list goes on..

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
