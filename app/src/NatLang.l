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
%x ST_ALT_N ST_ALT_V ST_ALT_A ST_TO ST_MODAL ST_Q_PRON
%x ST_ALT_SUFFIX_N ST_ALT_SUFFIX_V ST_ALT_SUFFIX_G ST_ALT_SUFFIX_A ST_ALT_SUFFIX_R

ws        [ \t\n]+
lit_char  [,()+\-*/^=]
digit     [0-9]
alpha     [a-zA-Z]
id        {alpha}|[_]|[']|[,]
lit_ident {id}+({digit}|{id})*
lit_int   {digit}+
lit_float {digit}*[.]{digit}+

eow       {ws}

pos_pron "my"|"your"|"our"|"his"|"her"|"their"
det_pron "this"|"that"|"these"|"those"|{pos_pron}

noun_pron     "i"|"you"|"he"|"she"|"it"|"we"|"us"|"they"|"them"|"him"|"her"|{det_pron}
noun_quantity "all"|"most"|"many"|"some"|"few"|"none"|"any"
noun          {noun_pron}|{noun_quantity}

q_pron "who"|"which"|"that"

aux_be   "am"|"is"|"are"|"was"|"were"|"being"|"been"
aux_do   "does"|"do"|"did"
aux_have "has"|"have"|"had"|"having"
aux       {aux_be}|{aux_do}|{aux_have}

verb_basic       {aux}|"made"|"chose"|"selected"
verb_life        "ate"|"slept"|"washed"
verb_motion      "moved"|"stayed"|"came"|"went"|"arrived"|"departed"|"walked"|"ran"|"flew"|"swam"|"crawled"|"dug"
verb_ownership   "gave"|"took"|"lent"|"borrowed"|"lost"|"found"
verb_container   "opened"|"closed"
verb_communicate "said"|"told"|"spoke"|"listened"
verb_commerce    "bought"|"sold"|"rented"
verb             {verb_basic}|{verb_life}|{verb_motion}|{verb_ownership}|{verb_container}|{verb_communicate}|{verb_commerce}

prep_basic              "to"|"from"|"of"|"for"|"in"|"on"|"at"|"by"|"as"|"than"|"about"
prep_spatial_distance   "near"|"far"
prep_spatial_transition "onto"|"into"|"through"|"across"
prep_spatial_container  "inside"|"outside"|"within"|"without"
prep_spatial_vertical   "above"|"below"|"over"|"under"|"underneath"|"beneath"
prep_spatial_order      "behind"|"before"|"after"|"beyond"|"around"|"between"
prep_spatial            {prep_spatial_distance}|{prep_spatial_transition}|{prep_spatial_container}|{prep_spatial_vertical}|{prep_spatial_order}
prep                    {prep_basic}|{prep_spatial}

adv   "quickly"|"slowly"|"always"|"never"|"sometimes"|"not"
modal "do"|"has"|"can"|"could"|"may"|"might"|"must"|"ought"|"shall"|"should"|"will"|"would"
det   "a"|"an"|"the"|{det_pron}
det2  "'s"
conj  "for"|"and"|"nor"|"but"|"or"|"yet"|"so"|"because"

suffix_n   "age"|"er"|"ian"|"ion"|"ist"|"ment"|"or"|"ty"|"ism"
suffix_v   "ate"|"ify"|"ize"|"ise"
suffix_g "ing"
suffix_a   "er"|"able"|"al"|"ful"|"ous"
suffix_r   "ly"

%%

 /*==========================================================================*/
 /* WHITE SPACE */

{ws}        {LOC;
                SCANNER_CONTEXT.m_word_index++;
            }

 /*==========================================================================*/
 /* GROUPED STATE TRANSITIONS */

"[]<"       { PUSH_STATE(ST_ALT); }
"[n]<"      { PUSH_STATE(ST_ALT_N); }
"[v]<"      { PUSH_STATE(ST_ALT_V); }
"[a]<"      { PUSH_STATE(ST_ALT_A); }
"[to]<"     { PUSH_STATE(ST_TO); }
"[modal]<"  { PUSH_STATE(ST_MODAL); }
"[q_pron]<" { PUSH_STATE(ST_Q_PRON); }
<ST_ALT,ST_ALT_N,ST_ALT_V,ST_ALT_A,ST_TO,ST_MODAL,ST_Q_PRON>">" { POP_STATE; }

 /*==========================================================================*/
 /* GROUPED STATEFUL LITERALS */

<ST_ALT_N>{noun}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_N;
            }

<ST_ALT_V>{verb}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_V;
            }

 /*
<ST_ALT_A>{adj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_A;
            }
 */

<ST_TO>"to"{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_TO;
            }

<ST_MODAL>{modal}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_MODAL;
            }

<ST_Q_PRON>{q_pron}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_Q_PRON;
            }

 /*==========================================================================*/
 /* UNGROUPED STATEFUL LITERALS */

<ST_ALT>{adv}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_R;
            }

<ST_ALT>{prep}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_P;
            }

<ST_ALT>{aux}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX;
            }

<ST_ALT>{det}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_D;
            }

<ST_ALT>{det2}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_D2;
            }

<ST_ALT>{conj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_C;
            }

<ST_ALT>[.] {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_EOS;
            }

<ST_ALT>[,] {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_COMMA;
            }

 /*==========================================================================*/
 /* GROUPED STATE CATCH-ALL */

<ST_ALT,ST_ALT_N,ST_ALT_V,ST_ALT_A,ST_TO,ST_MODAL,ST_Q_PRON>[^>] {LOC;
                return 0;
            }

 /*==========================================================================*/
 /* SUFFIX STATE TRANSITIONS */

"[suffix_n]<"   { PUSH_STATE(ST_ALT_SUFFIX_N); }
"[suffix_v]<"   { PUSH_STATE(ST_ALT_SUFFIX_V); }
"[suffix_g]<" { PUSH_STATE(ST_ALT_SUFFIX_G); }
"[suffix_a]<"   { PUSH_STATE(ST_ALT_SUFFIX_A); }
"[suffix_r]<"   { PUSH_STATE(ST_ALT_SUFFIX_R); }
<ST_ALT_SUFFIX_N,ST_ALT_SUFFIX_V,ST_ALT_SUFFIX_G,ST_ALT_SUFFIX_A,ST_ALT_SUFFIX_R>">" { POP_STATE; }

 /*==========================================================================*/
 /* SUFFIX STATEFUL LITERALS */

<ST_ALT_SUFFIX_N>[^>]+{suffix_n}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_N;
            }

<ST_ALT_SUFFIX_V>[^>]+{suffix_v}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_V;
            }

<ST_ALT_SUFFIX_G>[^>]+{suffix_g}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_G;
            }

<ST_ALT_SUFFIX_A>[^>]+{suffix_a}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_A;
            }

<ST_ALT_SUFFIX_R>[^>]+{suffix_r}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_R;
            }

 /*==========================================================================*/
 /* SUFFIX STATE CATCH-ALL */

<ST_ALT_SUFFIX_N,ST_ALT_SUFFIX_V,ST_ALT_SUFFIX_G,ST_ALT_SUFFIX_A,ST_ALT_SUFFIX_R>[^>] {LOC;
                return 0;
            }

 /*==========================================================================*/
 /* OTHER */

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
 /* OTHER CATCH-ALL */

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