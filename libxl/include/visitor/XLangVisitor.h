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

#ifndef XLANG_VISITOR_H_
#define XLANG_VISITOR_H_

#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "visitor/XLangVisitorIFace.h" // visitor::VisitorIFace
#include "visitor/XLangFilterable.h" // visitor::Filterable
#include "XLangString.h" // xl::escape
#include <sstream> // std::stringstream
#include <stack> // std::stack
#include <queue> // std::queue
#include <iostream> // std::cout

//#define DEBUG

namespace xl { namespace visitor {

template<class T>
class Visitor : public VisitorIFace<const node::NodeIdentIFace>, public Filterable
{
public:
    Visitor() : m_allow_visit_null(true)
    {}
    virtual ~Visitor()
    {}

    // required
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::INT>* _node)
    {
        std::cout << _node->value();
    }
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::FLOAT>* _node)
    {
        std::cout << _node->value();
    }
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::STRING>* _node)
    {
        std::cout << '\"' << xl::escape(*_node->value()) << '\"';
    }
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::CHAR>* _node)
    {
        std::cout << '\'' << xl::escape(_node->value()) << '\'';
    }
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::IDENT>* _node)
    {
        std::cout << *_node->value();
    }
    virtual void visit(const node::SymbolNodeIFace* _node) = 0;
    virtual void visit_null()
    {
        std::cout << "NULL";
    }
    void dispatch_visit(const node::NodeIdentIFace* unknown)
    {
        if(!unknown)
        {
            if(m_allow_visit_null)
                visit_null();
            return;
        }
        #ifdef DEBUG
            if(is_printer())
            {
                std::cout << "{depth=" << unknown->depth()
                          << ", height=" << unknown->height()
                          << ", bfs_index=" << unknown->bfs_index() << "}" << std::endl;
            }
        #endif
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
    bool next_child(
            const node::SymbolNodeIFace* _node = NULL, const node::NodeIdentIFace** ref_child = NULL)
    {
        if(_node)
            push_state(_node);
        get_current_node(ref_child);
        return next_state();
    }
    bool visit_next_child(
            const node::SymbolNodeIFace* _node = NULL, const node::NodeIdentIFace** ref_child = NULL)
    {
        const node::NodeIdentIFace* child = NULL;
        if(!next_child(_node, &child))
            return false;
        dispatch_visit(child);
        if(ref_child)
            *ref_child = child;
        return true;
    }
    void abort_visitation()
    {
        pop_state();
    }

    // optional
    void set_allow_visit_null(bool allow_visit_null)
    {
        m_allow_visit_null = allow_visit_null;
    }
    virtual bool is_printer() const = 0;

protected:
    typedef T                         visit_state_t;
    typedef std::stack<visit_state_t> visit_state_stack_t;

    visit_state_stack_t m_visit_state_stack;

    virtual void push_state(const node::SymbolNodeIFace* _node) = 0;
    virtual bool pop_state() = 0;
    virtual bool next_state() = 0;
    virtual bool get_current_node(const node::NodeIdentIFace** _node) const = 0;

private:
    bool m_allow_visit_null;
};

class VisitorDFS : public Visitor<std::pair<const node::SymbolNodeIFace*, int>>
{
public:
    using Visitor::visit;
    void visit(const node::SymbolNodeIFace* _node);

private:
    void push_state(const node::SymbolNodeIFace* _node);
    bool pop_state();
    bool next_state();
    bool get_current_node(const node::NodeIdentIFace** _node) const;
    bool end_of_visitation() const;
};

class VisitorBFS : public Visitor<std::queue<const node::NodeIdentIFace*>>
{
public:
    using Visitor::visit;

private:
    void push_state(const node::SymbolNodeIFace* _node);
    bool pop_state();
    bool next_state();
    bool get_current_node(const node::NodeIdentIFace** _node) const;
    bool end_of_visitation() const;
};

} }

#endif
