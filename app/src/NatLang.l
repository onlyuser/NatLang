/* NatLang
 * -- A parser framework for natural language processing
 * Copyright (C) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

%option outfile="lex.NatLang.c"
%option prefix="_NATLANG_"

%{

#include "NatLang.h"
#include "NatLang.tab.h" // ID_XXX (yacc generated)
#include "XLangString.h" // xl::unescape
#include <string.h> // memcpy
#include <stdlib.h> // atoi
#include <algorithm> // std::min
#include <iostream> // std::cout

// When in the lexer you have to access parm through the extra data.
#define PARM yyget_extra(yyscanner)->scanner_context()

// We want to read from a the buffer in parm so we have to redefine the
// YY_INPUT macro (see section 10 of the flex manual 'The generated scanner')
#define YY_INPUT(buf, result, max_size) \
    do { \
        if(PARM.m_pos >= PARM.m_length || (max_size)<1) { \
            (result) = YY_NULL; \
            break; \
        } else { \
            if('\n' == PARM.m_buf[PARM.m_pos]) { \
                PARM.m_line++; \
                PARM.m_column = 1; \
            } else \
                PARM.m_column++; \
            (buf)[0] = PARM.m_buf[PARM.m_pos]; \
            PARM.m_pos++; \
            (result) = 1; \
        } \
    } while(0)

#define LOC             begin_token(yyscanner, yyleng);
#define PUSH_STATE(x)   yy_push_state(x, yyscanner)
#define POP_STATE       yy_pop_state(yyscanner)
#define LVAL            (*yylval)
#define TREE_CONTEXT    yyget_extra(yyscanner)->tree_context()
#define SCANNER_CONTEXT yyget_extra(yyscanner)->scanner_context()

void begin_token(yyscan_t yyscanner, size_t length);

%}

%option noyywrap nounput noyy_top_state
%option reentrant bison-bridge bison-locations
%option stack
%x ST_ALT
%x ST_ALT_NOUN ST_ALT_VERB ST_ALT_ADJ ST_ALT_ADV
%x ST_ALT_SUFFIX_NOUN ST_ALT_SUFFIX_VERB ST_ALT_SUFFIX_ADJ ST_ALT_SUFFIX_ADV

ws        [ \t\n]+
lit_char  [,()+\-*/^=]
digit     [0-9]
alpha     [a-zA-Z]
id        {alpha}|[_]
lit_ident {id}+({digit}|{id})*
lit_int   {digit}+
lit_float {digit}*[.]{digit}+

eow       {ws}

noun_pron "i"|"you"|"he"|"she"|"it"|"we"|"us"|"they"|"them"|"him"|"her"
noun      {noun_pron}

prep_basic             "to"|"from"|"of"|"for"|"in"|"on"|"at"
prep_spatial_distance  "near"|"far"
prep_spatial_motion    "onto"|"into"|"through"
prep_spatial_container "inside"|"outside"|"within"|"without"
prep_spatial_vertical  "above"|"below"|"over"|"under"|"underneath"|"beneath"
prep_spatial_order     "behind"|"before"|"after"|"beyond"|"around"
prep_spatial           {prep_spatial_distance}|{prep_spatial_motion}|{prep_spatial_container}|{prep_spatial_vertical}|{prep_spatial_order}
prep                   {prep_basic}|{prep_spatial}
prep2                  "to2"|"from2"|"of2"|"for2"|"in2"|"on2"|"at2"

adv      "quickly"|"slowly"|"always"|"never"|"sometimes"
modal    "can"|"could"|"may"|"might"|"must"|"ought"|"shall"|"should"|"will"|"would"
neg      "not"
aux_be   "am"|"is"|"are"|"was"|"were"|"being"|"been"
aux_do   "does"|"do"|"did"
aux_have "has"|"have"|"had"|"having"
aux       {aux_be}|{aux_do}|{aux_have}
det       "a"|"an"|"the"|"this"|"that"|"these"|"those"
conj      "and"|"nor"|"but"|"or"|"yet"|"so"
conj2     "and2"|"nor2"|"but2"|"or2"|"yet2"|"so2"
conj3     "and3"|"nor3"|"but3"|"or3"|"yet3"|"so3"

suffix_noun "age"|"er"|"ian"|"ion"|"ist"|"ment"|"or"|"ty"|"ism"
suffix_verb "ate"|"ify"|"ize"|"ise"
suffix_adj  "able"|"al"|"ful"|"ous"
suffix_adv  "ly"

%%

{ws}        {LOC;
                SCANNER_CONTEXT.m_word_index++;
            }

 /*==========================================================================*/
 /* LITERALS */

"[]<"       { PUSH_STATE(ST_ALT); }
"[noun]<"   { PUSH_STATE(ST_ALT_NOUN); }
"[verb]<"   { PUSH_STATE(ST_ALT_VERB); }
"[adj]<"    { PUSH_STATE(ST_ALT_ADJ); }
"[adv]<"    { PUSH_STATE(ST_ALT_ADV); }
<ST_ALT,ST_ALT_NOUN,ST_ALT_VERB,ST_ALT_ADJ,ST_ALT_ADV>">" { POP_STATE; }

<ST_ALT_NOUN>{noun}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_NOUN;
            }

 /*
<ST_ALT_VERB>{verb}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_VERB;
            }

<ST_ALT_ADJ>{adj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADJ;
            }
 */

<ST_ALT_ADV>{adv}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADV;
            }

<ST_ALT>{modal}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_MODAL;
            }

<ST_ALT>{neg}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_NEG;
            }

<ST_ALT>{prep}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PREP;
            }

<ST_ALT>{prep2}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PREP_2;
            }

<ST_ALT>{aux}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX;
            }

<ST_ALT>{det}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_DET;
            }

<ST_ALT>{conj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ;
            }

<ST_ALT>{conj2}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ_2;
            }

<ST_ALT>{conj3}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ_3;
            }

<ST_ALT>[.] {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PERIOD;
            }

<ST_ALT,ST_ALT_NOUN,ST_ALT_VERB,ST_ALT_ADJ,ST_ALT_ADV>[^>] {LOC;
                return 0;
            }

"[suffix_noun]<" { PUSH_STATE(ST_ALT_SUFFIX_NOUN); }
"[suffix_verb]<" { PUSH_STATE(ST_ALT_SUFFIX_VERB); }
"[suffix_adj]<"  { PUSH_STATE(ST_ALT_SUFFIX_ADJ); }
"[suffix_adv]<"  { PUSH_STATE(ST_ALT_SUFFIX_ADV); }
<ST_ALT_SUFFIX_NOUN,ST_ALT_SUFFIX_VERB,ST_ALT_SUFFIX_ADJ,ST_ALT_SUFFIX_ADV>">" { POP_STATE; }

<ST_ALT_SUFFIX_NOUN>[^>]+{suffix_noun}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_NOUN;
            }

<ST_ALT_SUFFIX_VERB>[^>]+{suffix_verb}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_VERB;
            }

<ST_ALT_SUFFIX_ADJ>[^>]+{suffix_adj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADJ;
            }

<ST_ALT_SUFFIX_ADV>[^>]+{suffix_adv}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADV;
            }

<ST_ALT_SUFFIX_NOUN,ST_ALT_SUFFIX_VERB,ST_ALT_SUFFIX_ADJ,ST_ALT_SUFFIX_ADV>[^>] {LOC;
                return 0;
            }

{lit_ident}|[.] {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                uint32_t lexer_id = SCANNER_CONTEXT.current_lexer_id();
                //std::cout << yytext << "<" << id_to_name(lexer_id) << ">" << std::endl;
                if(lexer_id)
                    return lexer_id;
                return ID_IDENT;
            }

{lit_int}   {LOC;
                LVAL.int_value = atoi(yytext);
                return ID_INT;
            }

{lit_float} {LOC;
                LVAL.float_value = atof(yytext);
                return ID_FLOAT;
            }

{lit_char}  {LOC;
                return *yytext;
            }

 /*==========================================================================*/
 /* OTHER */

.           {LOC;
                _nl(error)("unknown character");
                YY_FLUSH_BUFFER;
            }

%%

void begin_token(yyscan_t yyscanner, size_t length)
{
    YYLTYPE* loc = yyget_lloc(yyscanner);
    loc->first_line    = PARM.m_line;
    loc->first_column  = PARM.m_prev_column;
    loc->last_line     = PARM.m_line;
    loc->last_column   = PARM.m_prev_column+length-1;
    PARM.m_prev_column = PARM.m_column;
    PARM.m_prev_column--; // compensate for 1-char over-read
}