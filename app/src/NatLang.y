// NatLang
// -- A parser framework for natural language processing
// Copyright (C) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
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
%name-prefix="_NATLANG_"

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
        case ID_AP:        return "AP";
        case ID_A:         return "A";
        case ID_AUX:       return "Aux";
        case ID_AX:        return "AX";
        case ID_AXX:       return "AXX";
        case ID_C_A:       return "C_A";
        case ID_C_NP:      return "C_NP";
        case ID_C_S:       return "C_S";
        case ID_C_VP:      return "C_VP";
        case ID_D2:        return "D2";
        case ID_DP2:       return "DP2";
        case ID_DP:        return "DP";
        case ID_D:         return "D";
        case ID_EOS:       return "$";
        case ID_INFIN:     return "Infin";
        case ID_MODAL:     return "Modal";
        case ID_NP:        return "NP";
        case ID_NPX:       return "NPX";
        case ID_N:         return "N";
        case ID_NX:        return "NX";
        case ID_PP:        return "PP";
        case ID_P:         return "P";
        case ID_Q_PRON:    return "Q_PRON";
        case ID_R_A:       return "R_A";
        case ID_R_V:       return "R_V";
        case ID_S:         return "S";
        case ID_SX:        return "SX";
        case ID_TO:        return "To";
        case ID_VP_INNER:  return "VP_Inner";
        case ID_VGP_INNER: return "VGP_Inner";
        case ID_VP:        return "VP";
        case ID_VPX:       return "VPX";
        case ID_V:         return "V";
        case ID_V_G:       return "V_G";
        case ID_VX:        return "VX";
        case ID_VGX:       return "VGX";
    }
    throw ERROR_LEXER_ID_NOT_FOUND;
    return "";
}
uint32_t name_to_id(std::string name)
{
    if(name == "A")         return ID_A;
    if(name == "R_V")       return ID_R_V;
    if(name == "R_A")       return ID_R_A;
    if(name == "AP")        return ID_AP;
    if(name == "AX")        return ID_AX;
    if(name == "AXX")       return ID_AXX;
    if(name == "Aux")       return ID_AUX;
    if(name == "C_A")       return ID_C_A;
    if(name == "C_NP")      return ID_C_NP;
    if(name == "C_S")       return ID_C_S;
    if(name == "C_VP")      return ID_C_VP;
    if(name == "D")         return ID_D;
    if(name == "D2")        return ID_D2;
    if(name == "DP")        return ID_DP;
    if(name == "DP2")       return ID_DP2;
    if(name == "float")     return ID_FLOAT;
    if(name == "ident")     return ID_IDENT;
    if(name == "Infin")     return ID_INFIN;
    if(name == "int")       return ID_INT;
    if(name == "Modal")     return ID_MODAL;
    if(name == "N")         return ID_N;
    if(name == "NPX")       return ID_NPX;
    if(name == "NP")        return ID_NP;
    if(name == "NX")        return ID_NX;
    if(name == "PP")        return ID_PP;
    if(name == "P")         return ID_P;
    if(name == "$")         return ID_EOS;
    if(name == "Q_PRON")    return ID_Q_PRON;
    if(name == "SX")        return ID_SX;
    if(name == "S")         return ID_S;
    if(name == "To")        return ID_TO;
    if(name == "V")         return ID_V;
    if(name == "V_G")       return ID_V_G;
    if(name == "VP_Inner")  return ID_VP_INNER;
    if(name == "VGP_Inner") return ID_VGP_INNER;
    if(name == "VPX")       return ID_VPX;
    if(name == "VP")        return ID_VP;
    if(name == "VX")        return ID_VX;
    if(name == "VGX")       return ID_VGX;
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
%type<symbol_value> S NP VP

// local constructs
%type<symbol_value> Infin VP_Inner VGP_Inner AP NX VX VGX AX

// lists
%type<symbol_value> SX NPX VPX AXX PP DP DP2

//=============================================================================
// non-terminal lvalue lexer IDs
//=============================================================================

// high-level constructs
%nonassoc ID_S ID_NP ID_VP

// local constructs
%nonassoc ID_INFIN ID_VP_INNER ID_VGP_INNER ID_AP ID_NX ID_VX ID_VGX ID_AX

// lists
%nonassoc ID_SX ID_NPX ID_VPX ID_AXX ID_PP ID_DP ID_DP2

//=============================================================================
// terminal lvalues
//=============================================================================

// descriptive words
%type<symbol_value> N V V_G A P

// functional words
%type<symbol_value> D D2 Aux Modal To Q_pron EOS

// ambiguous terminals
%type<symbol_value> C_S C_NP C_VP C_A R_V R_A

//=============================================================================
// terminal rvalues
//=============================================================================

// descriptive words
%token<ident_value> ID_N ID_V ID_V_G ID_A ID_P

// functional words
%token<ident_value> ID_D ID_D2 ID_AUX ID_MODAL ID_TO ID_Q_PRON ID_EOS

// ambiguous terminals
%token<ident_value> ID_C_S ID_C_NP ID_C_VP ID_C_A ID_R_V ID_R_A

%%

//=============================================================================
// NON-TERMINALS
//=============================================================================
// high-level constructs

root:
      SX EOS { pc->tree_context().root() = $1; YYACCEPT; }
    | error  { yyclearin; /* yyerrok; YYABORT; */ }
    ;

S:
      NPX VPX { $$ = MAKE_SYMBOL(ID_S, @$, 2, $1, $2); }
    ;

NP:
      NX              { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }             // john
    | DP              { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }             // the teacher
    | NX DP           { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }         // john the teacher
    | DP NX           { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }         // the teacher john
    | NX VGP_Inner    { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }         // john reading a book
    | VGP_Inner NX    { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }         // reading a book john
    | NX PP           { $$ = MAKE_SYMBOL(ID_NP, @$, 2, $1, $2); }         // john from work
    | NP Q_pron VP    { $$ = MAKE_SYMBOL(ID_NP, @$, 3, $1, $2, $3); }     // john who is here
    | NP Q_pron NP VP { $$ = MAKE_SYMBOL(ID_NP, @$, 4, $1, $2, $3, $4); } // john we know
    | Infin           { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }             // to bring it
    | VGP_Inner       { $$ = MAKE_SYMBOL(ID_NP, @$, 1, $1); }             // bringing it
    ;

VP:
      VP_Inner      { $$ = MAKE_SYMBOL(ID_VP, @$, 1, $1); }     // bring it
    | Aux VGP_Inner { $$ = MAKE_SYMBOL(ID_VP, @$, 2, $1, $2); } // is bringing it
    | Modal VP      { $$ = MAKE_SYMBOL(ID_VP, @$, 2, $1, $2); } // could bring it
    ;

//=============================================================================
// local constructs

Infin:
      To VP_Inner { $$ = MAKE_SYMBOL(ID_INFIN, @$, 2, $1, $2); } // to give
    ;

VP_Inner:
      VX         { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 1, $1); }         // bring
    | VX NPX     { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 2, $1, $2); }     // bring it
    | VX NPX NPX { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 3, $1, $2, $3); } // bring me it
    | VX NPX PP  { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 3, $1, $2, $3); } // bring it to me
    | VX AP      { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 2, $1, $2); }     // be mad about you
    | VX PP      { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 2, $1, $2); }     // beat around the bush
    | VX AXX     { $$ = MAKE_SYMBOL(ID_VP_INNER, @$, 2, $1, $2); }     // be happy
    ;

VGP_Inner:
      VGX         { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 1, $1); }         // bringing
    | VGX NPX     { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 2, $1, $2); }     // bringing it
    | VGX NPX NPX { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 3, $1, $2, $3); } // bringing me it
    | VGX NPX PP  { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 3, $1, $2, $3); } // bringing it to me
    | VGX AP      { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 2, $1, $2); }     // being mad about you
    | VGX PP      { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 2, $1, $2); }     // beating around the bush
    | VGX AXX     { $$ = MAKE_SYMBOL(ID_VGP_INNER, @$, 2, $1, $2); }     // being happy
    ;

AP:
      AXX PP { $$ = MAKE_SYMBOL(ID_AP, @$, 2, $1, $2); } // mad about you
    ;

NX:
      N     { $$ = MAKE_SYMBOL(ID_NX, @$, 1, $1); }     // dog
    | AXX N { $$ = MAKE_SYMBOL(ID_NX, @$, 2, $1, $2); } // big and red dog
    ;

VX:
      V     { $$ = MAKE_SYMBOL(ID_VX, @$, 1, $1); }     // run
    | R_V V { $$ = MAKE_SYMBOL(ID_VX, @$, 2, $1, $2); } // quickly run
    | V R_V { $$ = MAKE_SYMBOL(ID_VX, @$, 2, $1, $2); } // run quickly
    ;

VGX:
      V_G     { $$ = MAKE_SYMBOL(ID_VGX, @$, 1, $1); }     // running
    | R_V V_G { $$ = MAKE_SYMBOL(ID_VGX, @$, 2, $1, $2); } // quickly running
    | V_G R_V { $$ = MAKE_SYMBOL(ID_VGX, @$, 2, $1, $2); } // running quickly
    ;

AX:
      A     { $$ = MAKE_SYMBOL(ID_AX, @$, 1, $1); }     // red
    | R_A A { $$ = MAKE_SYMBOL(ID_AX, @$, 2, $1, $2); } // very red
    ;

//=============================================================================
// lists

SX:
      S         { $$ = MAKE_SYMBOL(ID_SX, @$, 1, $1); }         // i jump
    | SX C_S SX { $$ = MAKE_SYMBOL(ID_SX, @$, 3, $1, $2, $3); } // i jump and you jump
    ;

NPX:
      NP           { $$ = MAKE_SYMBOL(ID_NPX, @$, 1, $1); }         // jack
    | NPX C_NP NPX { $$ = MAKE_SYMBOL(ID_NPX, @$, 3, $1, $2, $3); } // jack and jill
    ;

VPX:
      VP           { $$ = MAKE_SYMBOL(ID_VPX, @$, 1, $1); }         // hit
    | VPX C_VP VPX { $$ = MAKE_SYMBOL(ID_VPX, @$, 3, $1, $2, $3); } // hit and run
    ;

AXX:
      AX          { $$ = MAKE_SYMBOL(ID_AXX, @$, 1, $1); }         // big
    | AXX AXX     { $$ = MAKE_SYMBOL(ID_AXX, @$, 2, $1, $2); }     // big red
    | AXX C_A AXX { $$ = MAKE_SYMBOL(ID_AXX, @$, 3, $1, $2, $3); } // big and red
    ;

PP:
      P NPX { $$ = MAKE_SYMBOL(ID_PP, @$, 2, $1, $2); } // around the corner
    | PP PP { $$ = MAKE_SYMBOL(ID_PP, @$, 2, $1, $2); } // around the corner across the street
    ;

DP:
      D NX     { $$ = MAKE_SYMBOL(ID_DP, @$, 2, $1, $2); }     // the man
    | D NX DP2 { $$ = MAKE_SYMBOL(ID_DP, @$, 3, $1, $2, $3); } // the man's wife
    ;

DP2:
      D2 NX     { $$ = MAKE_SYMBOL(ID_DP2, @$, 2, $1, $2); }     // 's wife
    | D2 NX DP2 { $$ = MAKE_SYMBOL(ID_DP2, @$, 3, $1, $2, $3); } // 's wife's sister
    ;

//=============================================================================
// TERMINALS
//=============================================================================
// descriptive words

N:
      ID_N { $$ = MAKE_SYMBOL(ID_N, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // dog
    ;

V:
      ID_V { $$ = MAKE_SYMBOL(ID_V, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // run
    ;

V_G:
      ID_V_G { $$ = MAKE_SYMBOL(ID_V_G, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // running
    ;

A:
      ID_A { $$ = MAKE_SYMBOL(ID_A, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // big
    ;

P:
      ID_P { $$ = MAKE_SYMBOL(ID_P, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
    ;

//=============================================================================
// functional words

D:
      ID_D { $$ = MAKE_SYMBOL(ID_D, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // the
    ;

D2:
      ID_D2 { $$ = MAKE_SYMBOL(ID_D2, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // 's
    ;

Aux:
      ID_AUX { $$ = MAKE_SYMBOL(ID_AUX, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // is/be/do/have
    ;

Modal:
      ID_MODAL { $$ = MAKE_SYMBOL(ID_MODAL, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // could
    ;

To:
      ID_TO { $$ = MAKE_SYMBOL(ID_TO, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // to
    ;

Q_pron:
      ID_Q_PRON { $$ = MAKE_SYMBOL(ID_Q_PRON, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // who/which/that
    ;

EOS:
      ID_EOS { $$ = MAKE_SYMBOL(ID_EOS, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
    ;

//=============================================================================
// ambiguous terminals

C_S:
      ID_C_S { $$ = MAKE_SYMBOL(ID_C_S, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for S)
    ;

C_NP:
      ID_C_NP { $$ = MAKE_SYMBOL(ID_C_NP, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for NP)
    ;

C_VP:
      ID_C_VP { $$ = MAKE_SYMBOL(ID_C_VP, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for VP)
    ;

C_A:
      ID_C_A { $$ = MAKE_SYMBOL(ID_C_A, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); } // and (for AX)
    ;

R_V:
      ID_R_V { $$ = MAKE_SYMBOL(ID_R_V, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
    ;

R_A:
      ID_R_A { $$ = MAKE_SYMBOL(ID_R_A, @$, 1, MAKE_TERM(ID_IDENT, @$, $1)); }
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
