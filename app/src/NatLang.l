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

ws        [ \t\n]+
lit_char  [,()+\-*/^=]
digit     [0-9]
alpha     [a-zA-Z]
id        {alpha}|[_]
lit_ident {id}+({digit}|{id})*
lit_int   {digit}+
lit_float {digit}*[.]{digit}+

noun_pron   "i"|"me"|"you"|"he"|"she"|"him"|"her"|"it"|"them"|"we"|"us"|"here"|"there"|"everywhere"|"nowhere"|"someone"|"somewhere"
noun_places "house"|"home"|"school"|"library"|"store"
noun_actors "boy"|"girl"|"man"|"woman"|"fox"|"dog"|"book"|"apple"
noun        {noun_pron}|{noun_places}|{noun_actors}

verb_motion_move "move"|"moves"|"moving"|"moved"
verb_motion_come "come"|"comes"|"coming"|"came"
verb_motion_go   "go"|"goes"|"going"|"went"|"gone"
verb_motion_run  "run"|"runs"|"running"|"ran"
verb_motion_jump "jump"|"jumps"|"jumping"|"jumped"
verb_motion      {verb_motion_move}|{verb_motion_come}|{verb_motion_go}|{verb_motion_run}|{verb_motion_jump}

verb_access_create  "create"|"creates"|"creating"|"created"
verb_access_destroy "destroy"|"destroys"|"destroying"|"destroyed"
verb_access_open    "open"|"opens"|"opening"|"opened"
verb_access_close   "close"|"closes"|"closing"|"closed"
verb_access_change  "change"|"changes"|"changing"|"changed"
verb_access         {verb_access_create}|{verb_access_destroy}|{verb_access_open}|{verb_access_close}|{verb_access_change}

verb_misc_do      "do"|"does"|"doing"|"did"|"done"
verb_misc_make    "make"|"makes"|"making"|"made"
verb_misc_get     "get"|"gets"|"getting"|"got"|"gotten"
verb_misc_put     "put"|"puts"|"putting"
verb_misc_give    "give"|"gives"|"giving"|"gave"|"given"
verb_misc_take    "take"|"takes"|"taking"|"took"|"taken"
verb_misc_receive "receive"|"receives"|"receiving"|"received"
verb_misc         {verb_misc_do}|{verb_misc_make}|{verb_misc_get}|{verb_misc_put}|{verb_misc_give}|{verb_misc_take}|{verb_misc_receive}

verb {verb_motion}|{verb_access}|{verb_misc}

adj_size  "big"|"small"
adj_color "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"black"|"white"|"brown"
adj_speed "fast"|"quick"|"slow"
adj       {adj_size}|{adj_color}|{adj_speed}|"lazy"

prep_basic             "to"|"from"|"of"|"in"|"on"|"at"
prep_spatial_distance  "near"|"far"
prep_spatial_motion    "onto"|"into"|"through"
prep_spatial_container "inside"|"outside"|"within"|"without"
prep_spatial_vertical  "above"|"below"|"over"|"under"|"underneath"|"beneath"
prep_spatial_order     "behind"|"before"|"after"|"beyond"|"around"
prep_spatial           {prep_spatial_distance}|{prep_spatial_motion}|{prep_spatial_container}|{prep_spatial_vertical}|{prep_spatial_order}
prep                   {prep_basic}|{prep_spatial}

adv   "quickly"|"slowly"
modal "always"|"must"|"will"|"would"|"may"|"might"|"could"|"can"|"cannot"|"not"|"never"|"very"
aux   "is"|"was"|"were"
det   "a"|"the"|"this"|"that"|"these"|"those"
conj  "for"|"and"|"nor"|"but"|"or"|"yet"|"so"
conj2 "for2"|"and2"|"nor2"|"but2"|"or2"|"yet2"|"so2"
conj3 "for3"|"and3"|"nor3"|"but3"|"or3"|"yet3"|"so3"

%%

{ws}        {LOC;
                SCANNER_CONTEXT.m_word_index++;
            }

 /*==========================================================================*/
 /* LITERALS */

"<"         {
                PUSH_STATE(ST_ALT);
            }

<ST_ALT>">" {
                POP_STATE;
            }

<ST_ALT>{noun} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_NOUN;
            }

<ST_ALT>{verb} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_VERB;
            }

<ST_ALT>{adj} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADJ;
            }

<ST_ALT>{adv} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_ADV;
            }

<ST_ALT>{modal} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_MODAL;
            }

<ST_ALT>{prep} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PREP;
            }

<ST_ALT>{aux} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_AUX;
            }

<ST_ALT>{det} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_DET;
            }

<ST_ALT>{conj} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ;
            }

<ST_ALT>{conj2} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ_2;
            }

<ST_ALT>{conj3} {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_CONJ_3;
            }

<ST_ALT>[.] {LOC;
                LVAL.ident_value = TREE_CONTEXT.alloc_unique_string(yytext);
                return ID_PERIOD;
            }

<ST_ALT>[^>] {LOC;
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