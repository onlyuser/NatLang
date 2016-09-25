// NatLang
// -- An English parser with an extensible grammar
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

#ifndef XLANG_MVC_MODEL_H_
#define XLANG_MVC_MODEL_H_

#include "XLangAlloc.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "node/XLangNode.h" // node::TermNode
#include "XLangTreeContext.h" // TreeContext
#include "XLangType.h" // uint32_t
#include "NatLangLexerIDWrapper.h" // YYLTYPE
#include <string> // std::string

namespace xl { namespace mvc {

struct MVCModel
{
    template<class T>
    static node::NodeIdentIFace* make_term(TreeContext* tc, uint32_t lexer_id, YYLTYPE loc, T value)
    {
        return new (PNEW_LOC(tc->alloc())) node::TermNode<
                static_cast<node::NodeIdentIFace::type_t>(node::TermType<T>::type)
                >(lexer_id, loc, value); // assumes trivial dtor
    }
    static node::SymbolNode* make_symbol(TreeContext* tc, uint32_t lexer_id, YYLTYPE loc, size_t size, ...);
    static node::SymbolNode* make_symbol(TreeContext* tc, uint32_t lexer_id, YYLTYPE loc, std::vector<node::NodeIdentIFace*>& vec);
    static node::NodeIdentIFace* make_ast(TreeContext* tc, std::string filename);
};

} }

#endif
