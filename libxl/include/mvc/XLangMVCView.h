// XLang
// -- A parser framework for language modeling
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

#ifndef XLANG_MVC_VIEW_H_
#define XLANG_MVC_VIEW_H_

#include "visitor/XLangVisitor.h" // visitor::VisitorDFS
#include "XLangType.h" // NULL

namespace xl { namespace node { class NodeIdentIFace; } }

namespace xl { namespace mvc {

struct MVCView
{
    static void annotate_tree(
            const node::NodeIdentIFace*      _node,
            visitor::Filterable::filter_cb_t filter_cb = NULL);
    static void print_lisp(
            const node::NodeIdentIFace*       _node,
            visitor::Filterable::filter_cb_t filter_cb = NULL);
    static void print_xml(
            const node::NodeIdentIFace*      _node,
            visitor::Filterable::filter_cb_t filter_cb = NULL);
    static void print_dot(
            const node::NodeIdentIFace* _node,
            bool                        horizontal          = false,
            bool                        print_digraph_block = true);
    static void print_dot_header(bool horizontal);
    static void print_dot_footer();
    static void print_graph(const node::NodeIdentIFace* p);
};

} }

#endif
