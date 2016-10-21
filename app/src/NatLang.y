// NatLang
// -- An English parser with an extensible grammar
// Copyright (Conj) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

//%output="NatLang.tab.c"
%name-prefix "_NATLANG_"

%{

#include "NatLang.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "NatLang.tab.h" // ID_XXX (yacc generated)
#include "XLangAlloc.h" // Allocator
#include "mvc/XLangMVCView.h" // mvc::MVCView
#include "mvc/XLangMVCModel.h" // mvc::MVCModel
#include "XLangTreeContext.h" // TreeContext
#include "XLangSystem.h" // xl::replace
#include "XLangString.h" // xl::replace
#include "XLangType.h" // uint32_t
#include "TryAllParses.h" // gen_variations
#include <stdio.h> // size_t
#include <stdarg.h> // va_start
#include <string.h> // strlen
#include <vector> // std::vector
#include <list> // std::list
#include <map> // std::map
#include <string> // std::string
#include <sstream> // std::stringstream
#include <iostream> // std::cout
#include <stdlib.h> // EXIT_SUCCESS
#include <getopt.h> // getopt_long

//#define DEBUG

#define MAKE_TERM(lexer_id, ...)   xl::mvc::MVCModel::make_term(&pc->tree_context(), lexer_id, ##__VA_ARGS__)
#define MAKE_SYMBOL(...)           xl::mvc::MVCModel::make_symbol(&pc->tree_context(), ##__VA_ARGS__)
#define ERROR_LEXER_ID_NOT_FOUND   "Missing lexer id handler. Did you forgot to register one?"
#define ERROR_LEXER_NAME_NOT_FOUND "Missing lexer name handler. Did you forgot to register one?"

// report error
void _nl(error)(YYLTYPE* loc, ParserContext* pc, yyscan_t scanner, const char* s)
{
    if(loc)
    {
        std::stringstream ss;
        int last_line_pos = 0;
        for(int i = pc->scanner_context().m_pos; i >= 0; i--)
        {
            if(pc->scanner_context().m_buf[i] == '\n')
            {
                last_line_pos = i+1;
                break;
            }
        }
        ss << &pc->scanner_context().m_buf[last_line_pos] << std::endl;
        ss << std::string(loc->first_column-1, '-') <<
                std::string(loc->last_column - loc->first_column + 1, '^') << std::endl <<
                loc->first_line << ":c" << loc->first_column << " to " <<
                loc->last_line << ":c" << loc->last_column << std::endl;
        error_messages() << ss.str();
    }
    error_messages() << s;
}
void _nl(error)(const char* s)
{
    _nl(error)(NULL, NULL, NULL, s);
}

// get resource
std::stringstream &error_messages()
{
    static std::stringstream _error_messages;
    return _error_messages;
}
void reset_error_messages()
{
    error_messages().str("");
    error_messages().clear();
}
std::string id_to_name(uint32_t lexer_id)
{
    static const char* _id_to_name[] = {
        "int",
        "float",
        "ident"
        };
    int index = static_cast<int>(lexer_id)-ID_BASE-1;
    if(index >= 0 && index < static_cast<int>(sizeof(_id_to_name)/sizeof(*_id_to_name)))
        return _id_to_name[index];
    switch(lexer_id)
    {
        //case ID_FLOAT:            return "float";
        //case ID_IDENT:            return "ident";
        //case ID_INT:              return "int";
        case ID_ADJ:              return "Adj";
        case ID_ADJX:             return "AdjX";
        case ID_ADJ_LIST:         return "Adj_list";
        case ID_ADV:              return "Adv";
        case ID_ADV_ADJ:          return "Adv_Adj";
        case ID_ADV_GERUND:       return "Adv_Gerund";
        case ID_ADV_MODAL:        return "Adv_Modal";
        case ID_ADV_V:            return "Adv_V";
        case ID_AUX_BE:           return "Aux_Be";
        case ID_AUX_BEX:          return "Aux_BeX";
        case ID_AUX_HAVE:         return "Aux_Have";
        case ID_COMMA:            return "Comma";
        case ID_COMMA_S:          return "Comma_S";
        case ID_CONJ:             return "Conj";
        case ID_CONJ_ADJ:         return "Conj_Adj";
        case ID_CONJ_NP:          return "Conj_NP";
        case ID_CONJ_PREP:        return "Conj_Prep";
        case ID_CONJ_S:           return "Conj_S";
        case ID_CONJ_VP:          return "Conj_VP";
        case ID_DET:              return "Det";
        case ID_EOS:              return "$";
        case ID_GERUND:           return "Gerund";
        case ID_GERUNDX:          return "GerundX";
        case ID_GERUNDXX:         return "GerundXX";
        case ID_INFIN:            return "Infin";
        case ID_MODAL:            return "Modal";
        case ID_MODALX:           return "ModalX";
        case ID_MODALXX:          return "ModalXX";
        case ID_N:                return "N";
        case ID_NP:               return "NP";
        case ID_NP_LIST:          return "NP_list";
        case ID_NX:               return "NX";
        case ID_NXX:              return "NXX";
        case ID_PASTPART:         return "PastPart";
        case ID_PREDICATE_COMPL:  return "Predicate_Compl";
        case ID_PREP:             return "Prep";
        case ID_PREP_N:           return "Prep_N";
        case ID_PREP_NX:          return "Prep_NX";
        case ID_PREP_S:           return "Prep_S";
        case ID_PREP_SX:          return "Prep_SX";
        case ID_PREP_SX_LIST:     return "Prep_SX_list";
        case ID_PREP_V:           return "Prep_V";
        case ID_PREP_VX:          return "Prep_VX";
        case ID_PREP_VX_LIST:     return "Prep_VX_list";
        case ID_QWORD_PRON:       return "QWord_Pron";
        case ID_S:                return "S";
        case ID_S_LIST:           return "S_list";
        case ID_TO:               return "To";
        case ID_TRANSITIVE_COMPL: return "Transitive_Compl";
        case ID_V:                return "V";
        case ID_VP:               return "VP";
        case ID_VP_LIST:          return "VP_list";
        case ID_VX:               return "VX";
        case ID_VXX:              return "VXX";
    }
    throw ERROR_LEXER_ID_NOT_FOUND;
    return "";
}
uint32_t name_to_id(std::string name)
{
    if(name == "$")                return ID_EOS;
    if(name == "Adj")              return ID_ADJ;
    if(name == "AdjX")             return ID_ADJX;
    if(name == "Adj_list")         return ID_ADJ_LIST;
    if(name == "Adv")              return ID_ADV;
    if(name == "Adv_Adj")          return ID_ADV_ADJ;
    if(name == "Adv_Gerund")       return ID_ADV_GERUND;
    if(name == "Adv_Modal")        return ID_ADV_MODAL;
    if(name == "Adv_V")            return ID_ADV_V;
    if(name == "Aux_Be")           return ID_AUX_BE;
    if(name == "Aux_BeX")          return ID_AUX_BEX;
    if(name == "Aux_Have")         return ID_AUX_HAVE;
    if(name == "Comma")            return ID_COMMA;
    if(name == "Comma_S")          return ID_COMMA_S;
    if(name == "Conj")             return ID_CONJ;
    if(name == "Conj_Adj")         return ID_CONJ_ADJ;
    if(name == "Conj_NP")          return ID_CONJ_NP;
    if(name == "Conj_Prep")        return ID_CONJ_PREP;
    if(name == "Conj_S")           return ID_CONJ_S;
    if(name == "Conj_VP")          return ID_CONJ_VP;
    if(name == "Det")              return ID_DET;
    if(name == "Gerund")           return ID_GERUND;
    if(name == "GerundX")          return ID_GERUNDX;
    if(name == "GerundXX")         return ID_GERUNDXX;
    if(name == "Infin")            return ID_INFIN;
    if(name == "Modal")            return ID_MODAL;
    if(name == "ModalX")           return ID_MODALX;
    if(name == "ModalXX")          return ID_MODALXX;
    if(name == "N")                return ID_N;
    if(name == "NP")               return ID_NP;
    if(name == "NP_list")          return ID_NP_LIST;
    if(name == "NX")               return ID_NX;
    if(name == "NXX")              return ID_NXX;
    if(name == "PastPart")         return ID_PASTPART;
    if(name == "Predicate_Compl")  return ID_PREDICATE_COMPL;
    if(name == "Prep")             return ID_PREP;
    if(name == "Prep_N")           return ID_PREP_N;
    if(name == "Prep_NX")          return ID_PREP_NX;
    if(name == "Prep_S")           return ID_PREP_S;
    if(name == "Prep_SX")          return ID_PREP_SX;
    if(name == "Prep_SX_list")     return ID_PREP_SX_LIST;
    if(name == "Prep_V")           return ID_PREP_V;
    if(name == "Prep_VX")          return ID_PREP_VX;
    if(name == "Prep_VX_list")     return ID_PREP_VX_LIST;
    if(name == "QWord_Pron")       return ID_QWORD_PRON;
    if(name == "S")                return ID_S;
    if(name == "S_list")           return ID_S_LIST;
    if(name == "To")               return ID_TO;
    if(name == "Transitive_Compl") return ID_TRANSITIVE_COMPL;
    if(name == "V")                return ID_V;
    if(name == "VP")               return ID_VP;
    if(name == "VP_list")          return ID_VP_LIST;
    if(name == "VX")               return ID_VX;
    if(name == "VXX")              return ID_VXX;
    if(name == "float")            return ID_FLOAT;
    if(name == "ident")            return ID_IDENT;
    if(name == "int")              return ID_INT;
    std::cout << name << std::endl;
    throw ERROR_LEXER_NAME_NOT_FOUND;
    return 0;
}

static void remap_pos_value_path_to_pos_lexer_id_path(
        const std::vector<std::string> &pos_value_path,    // IN
        std::vector<uint32_t>*          pos_lexer_id_path) // OUT
{
    if(!pos_lexer_id_path)
        return;
    for(auto p = pos_value_path.begin(); p != pos_value_path.end(); p++)
        pos_lexer_id_path->push_back(name_to_id(*p));
}

static std::string expand_contractions(std::string &sentence)
{
    std::string s = sentence;
    s = xl::replace(s, "n't", " not");
    s = xl::replace(s, "'ve", " have");
    s = xl::replace(s, "'m", " am");
    s = xl::replace(s, "'re", " are");
    s = xl::replace(s, "'s", " 's");
    s = xl::replace(s, ",", " , ");
    return s;
}

static bool filter_singleton(const xl::node::NodeIdentIFace* _node)
{
    if(_node->type() != xl::node::NodeIdentIFace::SYMBOL || _node->height() <= 1)
        return false;
    auto symbol = dynamic_cast<const xl::node::SymbolNodeIFace*>(_node);
    return symbol->size() == 1;
}

%}

// 'pure_parser' tells bison to use no global variables and create a
// reentrant parser (NOTE: deprecated, use "%define api.pure" instead).
%define api.pure
%parse-param {ParserContext* pc}
%parse-param {yyscan_t scanner}
%lex-param {scanner}

// show detailed parse errors
%error-verbose

// record where each token occurs in input
%locations

%nonassoc ID_BASE

%token<int_value>   ID_INT
%token<float_value> ID_FLOAT
%token<ident_value> ID_IDENT

//=============================================================================
// non-terminal lvalues
//=============================================================================

// high-level constructs
%type<symbol_value>
    NP
    S
    VP

// local constructs
%type<symbol_value>
    AdjX
    GerundX
    GerundXX
    Infin
    ModalX
    ModalXX
    NX
    NXX
    Prep_NX
    Prep_SX
    Prep_VX
    VX
    VXX

// lists
%type<symbol_value>
    Adj_list
    NP_list
    Prep_SX_list
    Prep_VX_list
    S_list
    VP_list

//=============================================================================
// non-terminal lvalue lexer IDs
//=============================================================================

// high-level constructs
%nonassoc
    ID_NP
    ID_S
    ID_VP

// local constructs
%nonassoc
    ID_ADJX
    ID_ADJXXX
    ID_GERUNDPX
    ID_GERUNDX
    ID_GERUNDXX
    ID_INFIN
    ID_MODALX
    ID_MODALXX
    ID_NX
    ID_NXX
    ID_PASTPARTX
    ID_PASTPARTXX
    ID_PREP_NX
    ID_PREP_SX
    ID_PREP_VX
    ID_VX
    ID_VXX

// lists
%nonassoc
    ID_ADJ_LIST
    ID_DETSUFFIXX
    ID_DETX
    ID_NP_LIST
    ID_PREP_SX_LIST
    ID_PREP_VX_LIST
    ID_PREPXX_N
    ID_PREPXX_S
    ID_PREPX_N
    ID_PREPX_S
    ID_S_LIST
    ID_VP_LIST

//=============================================================================
// terminal lvalues
//=============================================================================

// descriptive words
%type<symbol_value>
    Adj
    Gerund
    N
    PastPart
    Prep_N
    Prep_S
    Prep_V
    V

// functional words
%type<symbol_value>
    Aux_Be
    Aux_BeX
    Aux_Have
    Comma_S
    Det
    EOS
    Modal
    Predicate_Compl
    Transitive_Compl
    QWord_Pron
    To

// ambiguous terminals
%type<symbol_value>
    Adv_Adj
    Adv_Gerund
    Adv_Modal
    Adv_V
    Conj_Adj
    Conj_NP
    Conj_Prep
    Conj_S
    Conj_VP

//=============================================================================
// terminal rvalues
//=============================================================================

// descriptive words
%token<ident_value>
    ID_ADJ
    ID_GERUND
    ID_N
    ID_PASTPART
    ID_V

%token<ident_value> ID_PREP
%token<ident_value>
    ID_PREP_N
    ID_PREP_S
    ID_PREP_V

// functional words
%token<ident_value>
    ID_AUX_BE
    ID_AUX_BEX
    ID_AUX_DO
    ID_AUX_HAVE
    ID_DET
    ID_DETSUFFIX
    ID_EOS
    ID_MODAL ID
    ID_PREDICATE_COMPL
    ID_TRANSITIVE_COMPL
    ID_QWORD_PRON
    ID_TO

%token<ident_value> ID_COMMA
%token<ident_value>
    ID_COMMA_PREP
    ID_COMMA_PREP2
    ID_COMMA_QWORD
    ID_COMMA_S
    ID_COMMA_V

// ambiguous terminals
%token<ident_value> ID_CONJ
%token<ident_value>
    ID_CONJ_ADJ
    ID_CONJ_NP
    ID_CONJ_PREP
    ID_CONJ_S
    ID_CONJ_VP

%token<ident_value> ID_ADV
%token<ident_value>
    ID_ADV_ADJ
    ID_ADV_GERUND
    ID_ADV_MODAL
    ID_ADV_PASTPART
    ID_ADV_PREP
    ID_ADV_V

%%

//=============================================================================
// NON-TERMINALS
//=============================================================================
// high-level constructs

root:
      S_list EOS { pc->tree_context().root() = $1; YYACCEPT; }
    | error      { yyclearin; /* yyerrok; YYABORT; */ }
    ;

S:
      NP_list VP_list                      { $$ = MAKE_SYMBOL(ID_S, @$, 2, $1, $2); }     // he goes
    | Prep_SX_list Comma_S NP_list VP_list { $$ = MAKE_SYMBOL(ID_S, @$, 4, $1, $2, $3, $4); } // from here he goes
    ;

NP:
      GerundXX               { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }         // going
    | Infin                  { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }         // to be
    | NXX                    { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }         // john
    | NXX Prep_NX            { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }     // john from cali
    | NXX QWord_Pron VP_list { $$ = MAKE_SYMBOL(ID_NP, @$, 3, $1, $2, $3); } // john who is here
    | NP NP                  { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }     // john the doctor <==> the doctor john
    ;

VP:
      VXX                     { $$ = MAKE_SYMBOL(ID_VP, @$, 1, $1); }     // bring it
    | ModalXX VXX             { $$ = MAKE_SYMBOL(ID_VP, @$, 2, $1, $2); } // can bring it
    | Aux_BeX Predicate_Compl { $$ = MAKE_SYMBOL(ID_VP, @$, 2, $1, $2); } // is a dog
    ;

//=============================================================================
// local constructs

VXX:
      VX                  { $$ = MAKE_SYMBOL(ID_VXX, @$, 1, $1); }         // bring
    | VX Predicate_Compl  { $$ = MAKE_SYMBOL(ID_VXX, @$, 2, $1, $2); }     // bring it
    | VX Transitive_Compl { $$ = MAKE_SYMBOL(ID_GERUNDX, @$, 2, $1, $2); } // bring it to you
    ;

VX:
      V        { $$ = MAKE_SYMBOL(ID_VX, @$, 1, $1); } // bring
    | PastPart { $$ = MAKE_SYMBOL(ID_VX, @$, 1, $1); } // brought
    ;

GerundXX:
      GerundX            { $$ = MAKE_SYMBOL(ID_GERUNDXX, @$, 1, $1); }     // running
    | Adv_Gerund GerundX { $$ = MAKE_SYMBOL(ID_GERUNDXX, @$, 2, $1, $2); } // not running
    ;

GerundX:
      Gerund                  { $$ = MAKE_SYMBOL(ID_GERUNDX, @$, 1, $1); }     // bringing
    | Gerund Predicate_Compl  { $$ = MAKE_SYMBOL(ID_GERUNDX, @$, 2, $1, $2); } // bringing it
    | Gerund Transitive_Compl { $$ = MAKE_SYMBOL(ID_GERUNDX, @$, 2, $1, $2); } // bringing it to you
    ;

ModalXX:
      ModalX          { $$ = MAKE_SYMBOL(ID_MODALXX, @$, 1, $1); }     // will
    | ModalX Aux_Have { $$ = MAKE_SYMBOL(ID_MODALXX, @$, 2, $1, $2); } // will have
    ;

ModalX:
      Modal           { $$ = MAKE_SYMBOL(ID_MODALX, @$, 1, $1); }     // will
    | Modal Adv_Modal { $$ = MAKE_SYMBOL(ID_MODALX, @$, 2, $1, $2); } // will not
    ;

Predicate_Compl:
      NP_list      { $$ = MAKE_SYMBOL(ID_PREDICATE_COMPL, @$, 1, $1); } // john
    | Prep_VX_list { $$ = MAKE_SYMBOL(ID_PREDICATE_COMPL, @$, 1, $1); } // from here
    | Adj_list     { $$ = MAKE_SYMBOL(ID_PREDICATE_COMPL, @$, 1, $1); } // red
    ;

Transitive_Compl:
      NP_list NP_list      { $$ = MAKE_SYMBOL(ID_TRANSITIVE_COMPL, @$, 2, $1, $2); } // (bring) me it
    | NP_list Prep_VX_list { $$ = MAKE_SYMBOL(ID_TRANSITIVE_COMPL, @$, 2, $1, $2); } // (bring) it to me
    ;

NXX:
      NX     { $$ = MAKE_SYMBOL(ID_NXX, @$, 1, $1); }     // dog
    | Det NX { $$ = MAKE_SYMBOL(ID_NXX, @$, 2, $1, $2); } // the dog
    ;

NX:
      N      { $$ = MAKE_SYMBOL(ID_NX, @$, 1, $1); }     // dog
    | AdjX N { $$ = MAKE_SYMBOL(ID_NX, @$, 2, $1, $2); } // big dog
    ;

Prep_SX:
      Prep_S NP_list { $$ = MAKE_SYMBOL(ID_PREP_SX, @$, 2, $1, $2); } // from here
    ;

Prep_NX:
      Prep_N NP_list { $$ = MAKE_SYMBOL(ID_PREP_NX, @$, 2, $1, $2); } // from here
    ;

Prep_VX:
      Prep_V NP_list { $$ = MAKE_SYMBOL(ID_PREP_VX, @$, 2, $1, $2); } // from here
    ;

AdjX:
      Adj         { $$ = MAKE_SYMBOL(ID_ADJX, @$, 1, $1); }     // red
    | Adv_Adj Adj { $$ = MAKE_SYMBOL(ID_ADJX, @$, 2, $1, $2); } // not red
    ;

Infin:
      To VXX       { $$ = MAKE_SYMBOL(ID_INFIN, @$, 2, $1, $2); }     // to be
    | To Adv_V VXX { $$ = MAKE_SYMBOL(ID_INFIN, @$, 3, $1, $2, $3); } // to not be
    | Adv_V To VXX { $$ = MAKE_SYMBOL(ID_INFIN, @$, 3, $1, $2, $3); } // not to be
    ;

Aux_BeX:
      Aux_Be       { $$ = MAKE_SYMBOL(ID_AUX_BEX, @$, 1, $1); }     // is
    | Aux_Be Adv_V { $$ = MAKE_SYMBOL(ID_AUX_BEX, @$, 2, $1, $2); } // is not
    ;

//=============================================================================
// lists

S_list:
      S                    { $$ = MAKE_SYMBOL(ID_S_LIST, @$, 1, $1); }         // i jump
    | S_list Conj_S S_list { $$ = MAKE_SYMBOL(ID_S_LIST, @$, 3, $1, $2, $3); } // i jump and you jump
    ;

NP_list:
      NP                      { $$ = MAKE_SYMBOL(ID_NP_LIST, @$, 1, $1); }         // jack
    | NP_list Conj_NP NP_list { $$ = MAKE_SYMBOL(ID_NP_LIST, @$, 3, $1, $2, $3); } // jack and jill
    ;

VP_list:
      VP                      { $$ = MAKE_SYMBOL(ID_VP_LIST, @$, 1, $1); }         // hit
    | VP_list Conj_VP VP_list { $$ = MAKE_SYMBOL(ID_VP_LIST, @$, 3, $1, $2, $3); } // hit and run
    ;

Adj_list:
      AdjX               { $$ = MAKE_SYMBOL(ID_ADJ_LIST, @$, 1, $1); }         // big
    | AdjX AdjX          { $$ = MAKE_SYMBOL(ID_ADJ_LIST, @$, 2, $1, $2); }     // big red
    | AdjX Conj_Adj AdjX { $$ = MAKE_SYMBOL(ID_ADJ_LIST, @$, 3, $1, $2, $3); } // big and red
    ;

Prep_SX_list:
      Prep_SX                             { $$ = MAKE_SYMBOL(ID_PREP_SX_LIST, @$, 1, $1); }         // from here
    | Prep_SX_list Prep_SX_list           { $$ = MAKE_SYMBOL(ID_PREP_SX_LIST, @$, 2, $1, $2); }     // from here to there
    | Prep_SX_list Conj_Prep Prep_SX_list { $$ = MAKE_SYMBOL(ID_PREP_SX_LIST, @$, 3, $1, $2, $3); } // from here and to there
    ;

Prep_VX_list:
      Prep_VX                             { $$ = MAKE_SYMBOL(ID_PREP_VX_LIST, @$, 1, $1); }         // from here
    | Prep_VX_list Prep_VX_list           { $$ = MAKE_SYMBOL(ID_PREP_VX_LIST, @$, 2, $1, $2); }     // from here to there
    | Prep_VX_list Conj_Prep Prep_VX_list { $$ = MAKE_SYMBOL(ID_PREP_VX_LIST, @$, 3, $1, $2, $3); } // from here and to there
    ;

//=============================================================================
// TERMINALS
//=============================================================================
// descriptive words

N:
      ID_N { $$ = MAKE_SYMBOL(ID_N, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // dog
    ;

V:
      ID_V { $$ = MAKE_SYMBOL(ID_V, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // bring
    ;

Gerund:
      ID_GERUND { $$ = MAKE_SYMBOL(ID_GERUND, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // bringing
    ;

PastPart:
      ID_PASTPART { $$ = MAKE_SYMBOL(ID_PASTPART, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // brought
    ;

Adj:
      ID_ADJ { $$ = MAKE_SYMBOL(ID_ADJ, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // big
    ;

//=============================================================================
// functional words

Det:
      ID_DET { $$ = MAKE_SYMBOL(ID_DET, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // the
    ;

Aux_Be:
      ID_AUX_BE { $$ = MAKE_SYMBOL(ID_AUX_BE, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // be
    ;

Aux_Have:
      ID_AUX_HAVE { $$ = MAKE_SYMBOL(ID_AUX_HAVE, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // have
    ;

Modal:
      ID_MODAL { $$ = MAKE_SYMBOL(ID_MODAL, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // could
    ;

To:
      ID_TO { $$ = MAKE_SYMBOL(ID_TO, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // to
    ;

QWord_Pron:
      ID_QWORD_PRON { $$ = MAKE_SYMBOL(ID_QWORD_PRON, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // who/which/that
    ;

Comma_S:
      ID_COMMA_S { $$ = MAKE_SYMBOL(ID_COMMA_S, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
    ;

EOS:
      ID_EOS { $$ = MAKE_SYMBOL(ID_EOS, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
    ;

//=============================================================================
// ambiguous terminals

Conj_S:
      ID_CONJ_S { $$ = MAKE_SYMBOL(ID_CONJ_S, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for S)
    ;

Conj_NP:
      ID_CONJ_NP { $$ = MAKE_SYMBOL(ID_CONJ_NP, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for NP)
    ;

Conj_VP:
      ID_CONJ_VP { $$ = MAKE_SYMBOL(ID_CONJ_VP, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for VP)
    ;

Conj_Adj:
      ID_CONJ_ADJ { $$ = MAKE_SYMBOL(ID_CONJ_ADJ, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for Adj)
    ;

Conj_Prep:
      ID_CONJ_PREP { $$ = MAKE_SYMBOL(ID_CONJ_PREP, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for Prep)
    ;

Adv_V:
      ID_ADV_V { $$ = MAKE_SYMBOL(ID_ADV_V, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // not (for V)
    ;

Adv_Gerund:
      ID_ADV_GERUND { $$ = MAKE_SYMBOL(ID_ADV_GERUND, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // not (for Gerund)
    ;

Adv_Adj:
      ID_ADV_ADJ { $$ = MAKE_SYMBOL(ID_ADV_ADJ, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // not (for Adj)
    ;

Adv_Modal:
      ID_ADV_MODAL { $$ = MAKE_SYMBOL(ID_ADV_MODAL, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // not (for Modal)
    ;

Prep_S:
      ID_PREP_S { $$ = MAKE_SYMBOL(ID_PREP_S, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // from
    ;

Prep_N:
      ID_PREP_N { $$ = MAKE_SYMBOL(ID_PREP_N, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // from
    ;

Prep_V:
      ID_PREP_V { $$ = MAKE_SYMBOL(ID_PREP_V, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // from
    ;

//=============================================================================

%%

ScannerContext::ScannerContext(const char* buf)
    : m_scanner(NULL), m_buf(buf), m_pos(0), m_length(strlen(buf)),
      m_line(1), m_column(1), m_prev_column(1), m_word_index(0),
      m_pos_lexer_id_path(NULL)
{}

uint32_t ScannerContext::current_lexer_id()
{
    if(!m_pos_lexer_id_path)
    {
        throw ERROR_LEXER_ID_NOT_FOUND;
        return 0;
    }
    return (*m_pos_lexer_id_path)[m_word_index];
}

uint32_t quick_lex(const char* s)
{
    xl::Allocator alloc(__FILE__);
    ParserContext parser_context(alloc, s);
    yyscan_t scanner = parser_context.scanner_context().m_scanner;
    _nl(lex_init)(&scanner);
    _nl(set_extra)(&parser_context, scanner);
    YYSTYPE dummy_sa;
    YYLTYPE dummy_loc;
    uint32_t lexer_id = _nl(lex)(&dummy_sa, &dummy_loc, scanner); // scanner entry point
    _nl(lex_destroy)(scanner);
    return lexer_id;
}

xl::node::NodeIdentIFace* make_ast(
        xl::Allocator         &alloc,
        const char*            s,
        std::vector<uint32_t> &pos_lexer_id_path)
{
    ParserContext parser_context(alloc, s);
    parser_context.scanner_context().m_pos_lexer_id_path = &pos_lexer_id_path;
    yyscan_t scanner = parser_context.scanner_context().m_scanner;
    _nl(lex_init)(&scanner);
    _nl(set_extra)(&parser_context, scanner);
    int error_code = _nl(parse)(&parser_context, scanner); // parser entry point
    _nl(lex_destroy)(scanner);
    return (!error_code && error_messages().str().empty()) ? parser_context.tree_context().root() : NULL;
}

void display_usage(bool verbose)
{
    std::cout << "Usage: NatLang [-i] OPTION [-m]" << std::endl;
    if(verbose)
    {
        std::cout << "Parses input and prints a syntax tree to standard out" << std::endl
                << std::endl
                << "Input control:" << std::endl
                << "  -i, --in-xml FILENAME (de-serialize from xml)" << std::endl
                << "  -e, --expr EXPRESSION" << std::endl
                << std::endl
                << "Output control:" << std::endl
                << "  -l, --lisp" << std::endl
                << "  -x, --xml" << std::endl
                << "  -g, --graph" << std::endl
                << "  -d, --dot" << std::endl
                << "  -s, --skip_singleton" << std::endl
                << "  -m, --memory" << std::endl
                << "  -h, --help" << std::endl;
    }
    else
        std::cout << "Try `NatLang --help\' for more information." << std::endl;
}

struct options_t
{
    typedef enum
    {
        MODE_NONE,
        MODE_LISP,
        MODE_XML,
        MODE_GRAPH,
        MODE_DOT,
        MODE_HELP
    } mode_e;

    mode_e      mode;
    std::string in_xml;
    std::string expr;
    bool        dump_memory;
    bool        skip_singleton;

    options_t()
        : mode(MODE_NONE), dump_memory(false), skip_singleton(false)
    {}
};

bool extract_options_from_args(options_t* options, int argc, char** argv)
{
    if(!options)
        return false;
    int opt = 0;
    int longIndex = 0;
    static const char *optString = "i:e:lxgdsmh?";
    static const struct option longOpts[] = {
                { "in-xml",         required_argument, NULL, 'i' },
                { "expr",           required_argument, NULL, 'e' },
                { "lisp",           no_argument,       NULL, 'l' },
                { "xml",            no_argument,       NULL, 'x' },
                { "graph",          no_argument,       NULL, 'g' },
                { "dot",            no_argument,       NULL, 'd' },
                { "skip_singleton", no_argument,       NULL, 's' },
                { "memory",         no_argument,       NULL, 'm' },
                { "help",           no_argument,       NULL, 'h' },
                { NULL,             no_argument,       NULL, 0 }
            };
    opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    while(opt != -1)
    {
        switch(opt)
        {
            case 'i': options->in_xml = optarg; break;
            case 'e': options->expr = optarg; break;
            case 'l': options->mode = options_t::MODE_LISP; break;
            case 'x': options->mode = options_t::MODE_XML; break;
            case 'g': options->mode = options_t::MODE_GRAPH; break;
            case 'd': options->mode = options_t::MODE_DOT; break;
            case 's': options->skip_singleton = true; break;
            case 'm': options->dump_memory = true; break;
            case 'h':
            case '?': options->mode = options_t::MODE_HELP; break;
            case 0: // reserved
            default:
                break;
        }
        opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    }
    return options->mode != options_t::MODE_NONE || options->dump_memory;
}

struct pos_value_path_ast_tuple_t
{
    std::vector<std::string>  m_pos_value_path;
    xl::node::NodeIdentIFace* m_ast;
    int                       m_path_index;

    pos_value_path_ast_tuple_t(
            std::vector<std::string>  &pos_value_path,
            xl::node::NodeIdentIFace*  ast,
            int                        path_index)
        : m_pos_value_path(pos_value_path),
          m_ast(ast),
          m_path_index(path_index) {}
};

bool import_ast(
        options_t                   &options,
        xl::Allocator               &alloc,
        pos_value_path_ast_tuple_t*  pos_value_path_ast_tuple)
{
    if(!pos_value_path_ast_tuple)
        return false;
    if(options.in_xml.size())
    {
        #if 0 // NOTE: not supported
            xl::node::NodeIdentIFace* _ast = xl::mvc::MVCModel::make_ast(
                    new (PNEW(alloc, xl::, TreeContext)) xl::TreeContext(alloc),
                    options.in_xml);
            if(!_ast)
            {
                std::cerr << "ERROR: de-serialize from xml fail!" << std::endl;
                return false;
            }
            pos_value_path_ast_tuple->m_ast = _ast;
        #endif
    }
    else
    {
        std::vector<std::string> &pos_value_path = pos_value_path_ast_tuple->m_pos_value_path;
        std::string pos_value_path_str;
        for(auto p = pos_value_path.begin(); p != pos_value_path.end(); p++)
            pos_value_path_str.append(*p + " ");
        #ifdef DEBUG
            std::cerr << "INFO: import path #" <<
                    pos_value_path_ast_tuple->m_path_index <<
                    ": <" << pos_value_path_str << ">" << std::endl;
        #endif
        std::vector<uint32_t> pos_lexer_id_path;
        remap_pos_value_path_to_pos_lexer_id_path(pos_value_path, &pos_lexer_id_path);
        xl::node::NodeIdentIFace* _ast =
                make_ast(alloc, options.expr.c_str(), pos_lexer_id_path);
        if(!_ast)
        {
            #ifdef DEBUG
                std::cerr << "ERROR: " << error_messages().str().c_str() << std::endl;
            #endif
            reset_error_messages();
            pos_value_path_ast_tuple->m_ast = NULL;
            return false;
        }
        xl::mvc::MVCView::annotate_tree(_ast);
        pos_value_path_ast_tuple->m_ast = _ast;
    }
    return true;
}

void export_ast(
        options_t                  &options,
        pos_value_path_ast_tuple_t &pos_value_path_ast_tuple)
{
    xl::node::NodeIdentIFace* ast = pos_value_path_ast_tuple.m_ast;
    if(!ast)
        return;
    std::vector<std::string> &pos_value_path = pos_value_path_ast_tuple.m_pos_value_path;
    std::string pos_value_path_str;
    for(auto p = pos_value_path.begin(); p != pos_value_path.end(); p++)
        pos_value_path_str.append(*p + " ");
    std::cerr << "INFO: export path #" <<
            pos_value_path_ast_tuple.m_path_index <<
            ": <" << pos_value_path_str << ">" << std::endl;
    xl::visitor::Filterable::filter_cb_t filter_cb = NULL;
    if(options.skip_singleton)
    {
        filter_cb = filter_singleton;
        if(options.mode == options_t::MODE_GRAPH || options.mode == options_t::MODE_DOT)
        {
            std::cerr << "ERROR: \"skip_singleton\" not supported for this mode!" << std::endl;
            return;
        }
    }
    switch(options.mode)
    {
        case options_t::MODE_LISP:  xl::mvc::MVCView::print_lisp(ast, filter_cb); break;
        case options_t::MODE_XML:   xl::mvc::MVCView::print_xml(ast, filter_cb); break;
        case options_t::MODE_GRAPH: xl::mvc::MVCView::print_graph(ast); break;
        case options_t::MODE_DOT:   xl::mvc::MVCView::print_dot(ast, false, false); break;
        default:
            break;
    }
}

bool apply_options(options_t &options)
{
    if(options.mode == options_t::MODE_HELP)
    {
        display_usage(true);
        return true;
    }
    xl::Allocator alloc(__FILE__);
    if(options.expr.empty() || options.in_xml.size())
    {
        std::cerr << "ERROR: mode not supported!" << std::endl;
        if(options.dump_memory)
            alloc.dump(std::string(1, '\t'));
        return false;
    }
    std::list<std::vector<std::string>> pos_value_paths;
    std::string sentence = options.expr;
    options.expr = sentence = expand_contractions(sentence);
    build_pos_value_paths_from_sentence(&pos_value_paths, sentence);
    int path_index = 0;
    std::list<pos_value_path_ast_tuple_t> pos_value_path_ast_tuples;
    for(auto p = pos_value_paths.begin(); p != pos_value_paths.end(); p++)
    {
        pos_value_path_ast_tuples.push_back(pos_value_path_ast_tuple_t(*p, NULL, path_index));
        path_index++;
    }
    for(auto q = pos_value_path_ast_tuples.begin(); q != pos_value_path_ast_tuples.end(); q++)
    {
        try
        {
            if(!import_ast(options, alloc, &(*q)))
                continue;
        }
        catch(const char* s)
        {
            std::cerr << "ERROR: " << s << std::endl;
            continue;
        }
    }
    if(options.mode == options_t::MODE_DOT)
    {
        xl::mvc::MVCView::print_dot_header(false);
        for(auto r = pos_value_path_ast_tuples.begin(); r != pos_value_path_ast_tuples.end(); r++)
            export_ast(options, *r);
        xl::mvc::MVCView::print_dot_footer();
    }
    else
    {
        for(auto r = pos_value_path_ast_tuples.begin(); r != pos_value_path_ast_tuples.end(); r++)
            export_ast(options, *r);
    }
    if(options.dump_memory)
        alloc.dump(std::string(1, '\t'));
    return true;
}

void add_signal_handlers()
{
    xl::system::add_sighandler(SIGABRT, xl::system::backtrace_sighandler);
    xl::system::add_sighandler(SIGINT,  xl::system::backtrace_sighandler);
    xl::system::add_sighandler(SIGSEGV, xl::system::backtrace_sighandler);
    xl::system::add_sighandler(SIGFPE,  xl::system::backtrace_sighandler);
    xl::system::add_sighandler(SIGBUS,  xl::system::backtrace_sighandler);
    xl::system::add_sighandler(SIGILL,  xl::system::backtrace_sighandler);
}

int main(int argc, char** argv)
{
    add_signal_handlers();
    options_t options;
    if(!extract_options_from_args(&options, argc, argv))
    {
        display_usage(false);
        return EXIT_FAILURE;
    }
    options.expr.append(" .");
    if(!apply_options(options))
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}
