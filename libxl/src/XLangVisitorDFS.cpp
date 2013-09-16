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

#include "visitor/XLangVisitorDFS.h" // visitor::VisitorDFS
#include "XLangString.h" // xl::escape
#include <iostream> // std::cout

namespace xl { namespace visitor {

void VisitorDFS::visit(const node::TermNodeIFace<node::NodeIdentIFace::INT>* _node)
{
    std::cout << _node->value();
}

void VisitorDFS::visit(const node::TermNodeIFace<node::NodeIdentIFace::FLOAT>* _node)
{
    std::cout << _node->value();
}

void VisitorDFS::visit(const node::TermNodeIFace<node::NodeIdentIFace::STRING>* _node)
{
    std::cout << '\"' << xl::escape(*_node->value()) << '\"';
}

void VisitorDFS::visit(const node::TermNodeIFace<node::NodeIdentIFace::CHAR>* _node)
{
    std::cout << '\'' << xl::escape(_node->value()) << '\'';
}

void VisitorDFS::visit(const node::TermNodeIFace<node::NodeIdentIFace::IDENT>* _node)
{
    std::cout << *_node->value();
}

void VisitorDFS::visit(const node::SymbolNodeIFace* _node)
{
    while(visit_next_child(_node));
}

void VisitorDFS::visit_null()
{
    std::cout << "NULL";
}

void VisitorDFS::dispatch_visit(const node::NodeIdentIFace* unknown)
{
    if(!unknown)
    {
        if(m_allow_visit_null)
            visit_null();
        return;
    }
    switch(unknown->type())
    {
        case node::NodeIdentIFace::INT:
            visit(dynamic_cast<const node::TermNodeIFace<node::NodeIdentIFace::INT>*>(unknown));
            break;
        case node::NodeIdentIFace::FLOAT:
            visit(dynamic_cast<const node::TermNodeIFace<node::NodeIdentIFace::FLOAT>*>(unknown));
            break;
        case node::NodeIdentIFace::STRING:
            visit(dynamic_cast<const node::TermNodeIFace<node::NodeIdentIFace::STRING>*>(unknown));
            break;
        case node::NodeIdentIFace::CHAR:
            visit(dynamic_cast<const node::TermNodeIFace<node::NodeIdentIFace::CHAR>*>(unknown));
            break;
        case node::NodeIdentIFace::IDENT:
            visit(dynamic_cast<const node::TermNodeIFace<node::NodeIdentIFace::IDENT>*>(unknown));
            break;
        case node::NodeIdentIFace::SYMBOL:
            m_visit_state.push(0);
            visit(dynamic_cast<const node::SymbolNodeIFace*>(unknown));
            m_visit_state.pop();
            break;
        default:
            std::cout << "unknown node type" << std::endl;
            break;
    }
}

node::NodeIdentIFace* VisitorDFS::get_next_child(const node::SymbolNodeIFace* _node)
{
    int index = get_next_child_index(_node);
    if(index == -1)
        return NULL;
    node::NodeIdentIFace* child = (*_node)[index];
    if(index == static_cast<int>(_node->size())-1)
        abort_visitation(_node);
    return child;
}

bool VisitorDFS::visit_next_child(const node::SymbolNodeIFace* _node, node::NodeIdentIFace** ref_node)
{
    int index = get_next_child_index(_node);
    if(index == -1)
        return false;
    if(ref_node)
        *ref_node = (*_node)[index];
    dispatch_visit((*_node)[index]);
    if(index == static_cast<int>(_node->size())-1)
    {
        abort_visitation(_node);
        return false;
    }
    return true;
}

void VisitorDFS::abort_visitation(const node::SymbolNodeIFace* _node)
{
    if(m_visit_state.size())
        m_visit_state.top() = -1;
}

int VisitorDFS::get_next_child_index(const node::SymbolNodeIFace* _node)
{
    if(m_visit_state.empty())
        return -1;
    if(m_visit_state.top() < static_cast<int>(_node->size()))
        return m_visit_state.top()++;
    return m_visit_state.top() = -1;
}

} }
