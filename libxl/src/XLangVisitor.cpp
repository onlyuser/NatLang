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

#include "visitor/XLangVisitor.h" // visitor::VisitorDFS
#include "XLangString.h" // xl::escape
#include <iostream> // std::cout

//#define DEBUG

namespace xl { namespace visitor {

void Visitor::visit(const node::TermNodeIFace<node::NodeIdentIFace::INT>* _node)
{
    std::cout << _node->value();
}

void Visitor::visit(const node::TermNodeIFace<node::NodeIdentIFace::FLOAT>* _node)
{
    std::cout << _node->value();
}

void Visitor::visit(const node::TermNodeIFace<node::NodeIdentIFace::STRING>* _node)
{
    std::cout << '\"' << xl::escape(*_node->value()) << '\"';
}

void Visitor::visit(const node::TermNodeIFace<node::NodeIdentIFace::CHAR>* _node)
{
    std::cout << '\'' << xl::escape(_node->value()) << '\'';
}

void Visitor::visit(const node::TermNodeIFace<node::NodeIdentIFace::IDENT>* _node)
{
    std::cout << *_node->value();
}

void Visitor::visit_null()
{
    std::cout << "NULL";
}

void Visitor::dispatch_visit(const node::NodeIdentIFace* unknown)
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
            visit(dynamic_cast<const node::SymbolNodeIFace*>(unknown));
            break;
        default:
            std::cout << "unknown node type" << std::endl;
            break;
    }
}

void VisitorDFS::visit(const node::SymbolNodeIFace* _node)
{
    #ifdef DEBUG
        std::cout << "depth: " << _node->depth() << std::endl;
        std::cout << "height: " << _node->height() << std::endl;
    #endif
    if(m_filter_cb)
    {
        const node::NodeIdentIFace* child = NULL;
        if(next_child(_node, &child))
        {
            do
            {
                if(m_filter_cb(child) && child->type() == node::NodeIdentIFace::SYMBOL)
                {
                    VisitorDFS::visit(dynamic_cast<const node::SymbolNodeIFace*>(child));
                    continue;
                }
                dispatch_visit(child);
            } while(next_child(NULL, &child));
        }
        return;
    }
    if(visit_next_child(_node))
        while(visit_next_child());
}

void VisitorDFS::dispatch_visit(const node::NodeIdentIFace* unknown)
{
    Visitor::dispatch_visit(unknown);
}

bool VisitorDFS::next_child(const node::SymbolNodeIFace* _node, const node::NodeIdentIFace** ref_child)
{
    if(_node)
        push_state(_node);
    get_current_node(ref_child);
    return next_state();
}

bool VisitorDFS::visit_next_child(const node::SymbolNodeIFace* _node, const node::NodeIdentIFace** ref_child)
{
    const node::NodeIdentIFace* child = NULL;
    if(!next_child(_node, &child))
        return false;
    dispatch_visit(child);
    if(ref_child)
        *ref_child = child;
    return true;
}

void VisitorDFS::abort_visitation()
{
    pop_state();
}

void VisitorDFS::push_state(const node::SymbolNodeIFace* _node)
{
    m_visit_state_stack.push(visit_state_t(_node, 0));
}

bool VisitorDFS::pop_state()
{
    if(m_visit_state_stack.empty())
        return false;
    m_visit_state_stack.pop();
    return true;
}

bool VisitorDFS::next_state()
{
    if(end_of_visitation())
    {
        pop_state();
        return false;
    }
    m_visit_state_stack.top().second++;
    return true;
}

bool VisitorDFS::get_current_node(const node::NodeIdentIFace** _node) const
{
    if(end_of_visitation())
        return false;
    visit_state_t visit_state = m_visit_state_stack.top();
    if(_node)
        *_node = (*visit_state.first)[visit_state.second];
    return true;
}

bool VisitorDFS::end_of_visitation() const
{
    if(m_visit_state_stack.empty())
        return true;
    return m_visit_state_stack.top().second == static_cast<int>(m_visit_state_stack.top().first->size());
}

} }
