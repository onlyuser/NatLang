/* NatLang
 * -- An English parser with an extensible grammar
 * Copyright (C) 2011 onlyuser <mailto:onlyuser@gmail.com>
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
%x ST_ALT_N ST_ALT_V ST_ALT_PASTPART ST_ALT_ADJ ST_TO ST_MODAL ST_QWORD_PRON
%x ST_ALT_SUFFIX_N ST_ALT_SUFFIX_V ST_ALT_SUFFIX_GERUND ST_ALT_SUFFIX_PASTPART ST_ALT_SUFFIX_ADJ ST_ALT_SUFFIX_ADV

ws        [ \t\n]+
lit_char  [,()+\-*/^=]
digit     [0-9]
alpha     [a-zA-Z]
id        {alpha}|[_]|[']|[,]
lit_ident {id}+({digit}|{id})*
lit_int   {digit}+
lit_float {digit}*[.]{digit}+

eow {ws}

pos_pron "my"|"your"|"our"|"his"|"her"|"their"
det_pron "this"|"that"|"these"|"those"|{pos_pron}

noun_pron     "i"|"you"|"he"|"she"|"it"|"we"|"us"|"they"|"them"|"him"|"her"|{det_pron}
noun_quantity "all"|"most"|"many"|"some"|"few"|"none"|"any"
noun          {noun_pron}|{noun_quantity}

qword_pron "who"|"which"|"that"

aux_be   "am"|"is"|"are"|"was"|"were"
aux_do   "do"|"does"|"did"
aux_have "have"|"has"|"had"
aux      {aux_be}|{aux_do}|{aux_have}

verb_basic       {aux}|"made"|"chose"|"selected"
verb_life        "ate"|"slept"|"washed"
verb_motion      "moved"|"stayed"|"came"|"went"|"left"|"gone"|"arrived"|"departed"|"walked"|"ran"|"flew"|"swam"|"crawled"|"dug"
verb_ownership   "gave"|"took"|"lent"|"borrowed"|"lost"|"found"
verb_container   "opened"|"closed"
verb_communicate "said"|"told"|"spoke"|"listened"
verb_commerce    "bought"|"sold"|"rented"
verb             {verb_basic}|{verb_life}|{verb_motion}|{verb_ownership}|{verb_container}|{verb_communicate}|{verb_commerce}

pastpart "been"|"done"|"had"|"gone"

prep_basic              "to"|"from"|"of"|"for"|"in"|"on"|"at"|"by"|"as"|"than"|"about"
prep_spatial_distance   "near"|"far"
prep_spatial_transition "onto"|"into"|"through"|"across"
prep_spatial_container  "inside"|"outside"|"within"|"without"
prep_spatial_vertical   "above"|"below"|"over"|"under"|"underneath"|"beneath"
prep_spatial_order      "behind"|"before"|"after"|"beyond"|"around"|"between"
prep_spatial            {prep_spatial_distance}|{prep_spatial_transition}|{prep_spatial_container}|{prep_spatial_vertical}|{prep_spatial_order}
prep                    {prep_basic}|{prep_spatial}

adv       "quickly"|"slowly"|"always"|"never"|"sometimes"|"not"
modal     "can"|"could"|"may"|"might"|"must"|"ought"|"shall"|"should"|"will"|"would"|{aux}
det       "a"|"an"|"the"|{det_pron}
detsuffix "'s"
conj      "for"|"and"|"nor"|"but"|"or"|"yet"|"so"|"because"|"notwithstanding"

suffix_n        "age"|"er"|"ian"|"ion"|"ist"|"ment"|"or"|"ty"|"ism"
suffix_v        "ate"|"ify"|"ize"|"ise"
suffix_gerund   "ing"
suffix_pastpart "en"|"ought"|"aught"
suffix_adj      "er"|"able"|"al"|"ful"|"ous"
suffix_adv      "ly"

%%

 /*==========================================================================*/
 /* WHITE SPACE */

{ws}        {LOC;
                SCANNER_CONTEXT.m_word_index++;
            }

 /*==========================================================================*/
 /* GROUPED STATE TRANSITIONS */

"[]<"           { PUSH_STATE(ST_ALT); }
"[n]<"          { PUSH_STATE(ST_ALT_N); }
"[v]<"          { PUSH_STATE(ST_ALT_V); }
"[pastpart]<"   { PUSH_STATE(ST_ALT_PASTPART); }
"[adj]<"        { PUSH_STATE(ST_ALT_ADJ); }
"[to]<"         { PUSH_STATE(ST_TO); }
"[modal]<"      { PUSH_STATE(ST_MODAL); }
"[qword_pron]<" { PUSH_STATE(ST_QWORD_PRON); }
<ST_ALT,ST_ALT_N,ST_ALT_V,ST_ALT_PASTPART,ST_ALT_ADJ,ST_TO,ST_MODAL,ST_QWORD_PRON>">" { POP_STATE; }

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

<ST_ALT_PASTPART>{pastpart}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PASTPART;
            }

 /*
<ST_ALT_ADJ>{adj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADJ;
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

<ST_QWORD_PRON>{qword_pron}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_QWORD_PRON;
            }

 /*==========================================================================*/
 /* UNGROUPED STATEFUL LITERALS */

<ST_ALT>{adv}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADV;
            }

<ST_ALT>{prep}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PREP;
            }

<ST_ALT>{aux_be}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX_BE;
            }

<ST_ALT>{aux_do}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX_DO;
            }

<ST_ALT>{aux_have}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX_HAVE;
            }

<ST_ALT>{det}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_DET;
            }

<ST_ALT>{detsuffix}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_DETSUFFIX;
            }

<ST_ALT>{conj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ;
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

<ST_ALT,ST_ALT_N,ST_ALT_V,ST_ALT_PASTPART,ST_ALT_ADJ,ST_TO,ST_MODAL,ST_QWORD_PRON>[^>] {LOC;
                return 0;
            }

 /*==========================================================================*/
 /* SUFFIX STATE TRANSITIONS */

"[suffix_n]<"        { PUSH_STATE(ST_ALT_SUFFIX_N); }
"[suffix_v]<"        { PUSH_STATE(ST_ALT_SUFFIX_V); }
"[suffix_gerund]<"   { PUSH_STATE(ST_ALT_SUFFIX_GERUND); }
"[suffix_pastpart]<" { PUSH_STATE(ST_ALT_SUFFIX_PASTPART); }
"[suffix_adj]<"      { PUSH_STATE(ST_ALT_SUFFIX_ADJ); }
"[suffix_adv]<"      { PUSH_STATE(ST_ALT_SUFFIX_ADV); }
<ST_ALT_SUFFIX_N,ST_ALT_SUFFIX_V,ST_ALT_SUFFIX_GERUND,ST_ALT_SUFFIX_PASTPART,ST_ALT_SUFFIX_ADJ,ST_ALT_SUFFIX_ADV>">" { POP_STATE; }

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

<ST_ALT_SUFFIX_GERUND>[^>]+{suffix_gerund}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_GERUND;
            }

<ST_ALT_SUFFIX_PASTPART>[^>]+{suffix_pastpart}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PASTPART;
            }

<ST_ALT_SUFFIX_ADJ>[^>]+{suffix_adj}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADJ;
            }

<ST_ALT_SUFFIX_ADV>[^>]+{suffix_adv}{eow} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADV;
            }

 /*==========================================================================*/
 /* SUFFIX STATE CATCH-ALL */

<ST_ALT_SUFFIX_N,ST_ALT_SUFFIX_V,ST_ALT_SUFFIX_GERUND,ST_ALT_SUFFIX_PASTPART,ST_ALT_SUFFIX_ADJ,ST_ALT_SUFFIX_ADV>[^>] {LOC;
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
                yyerror("unknown character");
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