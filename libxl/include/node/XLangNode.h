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

#ifndef XLANG_NODE_H_
#define XLANG_NODE_H_

#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "visitor/XLangVisitable.h" // visitor::Visitable
#include "XLangTreeContext.h" // TreeContext
#include "XLangType.h" // uint32_t
#include <string> // std::string
#include <vector> // std::vector
#include <stdarg.h> // va_list

namespace xl { namespace node {

class Node : virtual public NodeIdentIFace
{
public:
    Node(NodeIdentIFace::type_t _type, uint32_t _lexer_id)
        : m_type(_type), m_lexer_id(_lexer_id), m_parent(NULL), m_original(NULL)
    {}

    // required
    NodeIdentIFace::type_t type() const
    {
        return m_type;
    }
    uint32_t lexer_id() const
    {
        return m_lexer_id;
    }
    std::string name() const;
    void set_parent(NodeIdentIFace* parent)
    {
        m_parent = parent;
    }
    NodeIdentIFace* parent() const
    {
        return m_parent;
    }
    std::string uid() const;

    // optional
    void detach();
    int index() const;
    void set_original(const NodeIdentIFace* original)
    {
        m_original = original;
    }
    const NodeIdentIFace* original() const
    {
        return m_original ? m_original : this;
    }

protected:
    NodeIdentIFace::type_t m_type;
    uint32_t m_lexer_id;
    NodeIdentIFace* m_parent;
    const NodeIdentIFace* m_original;
};

template<NodeIdentIFace::type_t _type>
class TermNode
    : public Node, public TermNodeIFace<_type>, public visitor::Visitable<TermNode<_type>>
{
public:
    TermNode(uint32_t _lexer_id, typename TermInternalType<_type>::type _value)
        : Node(_type, _lexer_id), visitor::Visitable<TermNode<_type>>(this), m_value(_value)
    {}
    typename TermInternalType<_type>::type value() const
    {
        return m_value;
    }
    NodeIdentIFace* clone(TreeContext* tc) const
    {
        return new (PNEW_LOC(tc->alloc()))
                TermNode<_type>(m_lexer_id, m_value); // assumes trivial dtor
    }
    bool compare(const NodeIdentIFace* _node) const
    {
        if(!is_same_type(_node))
            return false;
        return m_value == dynamic_cast<const TermNode<_type>*>(_node)->value();
    }

private:
    typename TermInternalType<_type>::type m_value;
};

class SymbolNode
    : public Node, public SymbolNodeIFace, public visitor::Visitable<SymbolNode>
{
public:
    SymbolNode(uint32_t _lexer_id, size_t _size, va_list ap);
    SymbolNode(uint32_t _lexer_id, std::vector<NodeIdentIFace*>& vec);

    // required
    NodeIdentIFace* operator[](uint32_t index) const
    {
        return m_child_vec[index];
    }
    size_t size() const
    {
        return m_child_vec.size();
    }

    // optional
    NodeIdentIFace* clone(TreeContext* tc) const;
    bool compare(const NodeIdentIFace* _node) const
    {
        if(!is_same_type(_node))
            return false;
        auto symbol_node = dynamic_cast<const SymbolNode*>(_node);
        if(m_child_vec.size() != symbol_node->size())
            return false;
        for(size_t i = 0; i<m_child_vec.size(); i++)
        {
            if(!m_child_vec[i]->compare(const_cast<const NodeIdentIFace*>((*symbol_node)[i])))
                return false;
        }
        return true;
    }
    NodeIdentIFace* find(const NodeIdentIFace* _node) const
    {
        for(auto p = m_child_vec.begin(); p != m_child_vec.end(); p++)
        {
            if((*p)->compare(_node))
                return (*p);
        }
        return NULL;
    }
    void push_back(NodeIdentIFace* _node);
    void push_front(NodeIdentIFace* _node);
    void insert_after(NodeIdentIFace* after_node, NodeIdentIFace* _node);
    void remove_first(NodeIdentIFace* _node);
    void replace_first(NodeIdentIFace* find_node, NodeIdentIFace* replace_node);
    void erase(int index);
    NodeIdentIFace* find_if(bool (*pred)(const NodeIdentIFace* _node)) const;

    // built-in
    static NodeIdentIFace* eol()
    {
        static int dummy;
        return reinterpret_cast<NodeIdentIFace*>(&dummy);
    }

private:
    std::vector<NodeIdentIFace*> m_child_vec;
};

} }

#endif
