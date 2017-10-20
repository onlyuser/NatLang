// XLang
// -- A parser framework for language modeling
// Copyright (C) 2011 onlyuser <mailto:onlyuser@gmail.com>
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
#include <stack> // std::stack
#include <queue> // std::queue

namespace xl { namespace visitor {

class Visitor : virtual public VisitorIFace<const node::NodeIdentIFace>
{
public:
    Visitor() : m_allow_visit_null(true)
    {}
    virtual ~Visitor()
    {}

    // required
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::INT>*    _node);
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::FLOAT>*  _node);
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::STRING>* _node);
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::CHAR>*   _node);
    virtual void visit(const node::TermNodeIFace<node::NodeIdentIFace::IDENT>*  _node);
    virtual void visit(const node::SymbolNodeIFace* _node) = 0;
    virtual void visit_null();
    void dispatch_visit(const node::NodeIdentIFace* unknown);

    // optional
    void set_allow_visit_null(bool allow_visit_null)
    {
        m_allow_visit_null = allow_visit_null;
    }
    virtual bool is_printer() const = 0;

private:
    bool m_allow_visit_null;
};

template<class T>
class StackedVisitor : virtual public VisitorIFace<const node::NodeIdentIFace>
{
public:
    typedef bool (*filter_cb_t)(const node::NodeIdentIFace*);

    StackedVisitor() : m_filter_cb(NULL)
    {}
    virtual ~StackedVisitor()
    {}

    // required
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

    // optional
    void abort_visitation()
    {
        pop_state();
    }
    void set_filter_cb(filter_cb_t filter_cb)
    {
        m_filter_cb = filter_cb;
    }

protected:
    typedef T                         visit_state_t;
    typedef std::stack<visit_state_t> visit_state_stack_t;

    visit_state_stack_t m_visit_state_stack;
    filter_cb_t         m_filter_cb;

    virtual void push_state(const node::SymbolNodeIFace* _node) = 0;
    bool pop_state()
    {
        if(m_visit_state_stack.empty())
            return false;
        m_visit_state_stack.pop();
        return true;
    }
    virtual bool next_state() = 0;
    virtual bool get_current_node(const node::NodeIdentIFace** _node) const = 0;
};

class VisitorDFS : public Visitor, public StackedVisitor<std::pair<const node::SymbolNodeIFace*, int>>
{
public:
    using Visitor::visit;
    void visit(const node::SymbolNodeIFace* _node);

private:
    void push_state(const node::SymbolNodeIFace* _node);
    bool next_state();
    bool get_current_node(const node::NodeIdentIFace** _node) const;
    bool end_of_visitation() const;
};

class VisitorBFS : public Visitor, public StackedVisitor<std::queue<const node::NodeIdentIFace*>>
{
public:
    using Visitor::visit;

private:
    void push_state(const node::SymbolNodeIFace* _node);
    bool next_state();
    bool get_current_node(const node::NodeIdentIFace** _node) const;
    bool end_of_visitation() const;
};

} }

#endif
