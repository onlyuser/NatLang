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

#ifndef XLANG_NODE_IFACE_H_
#define XLANG_NODE_IFACE_H_

#include "visitor/XLangVisitable.h" // visitor::Visitable
#include "XLangType.h" // uint32_t
#include <string> // std::string

namespace xl { class TreeContext; }

namespace xl { namespace node {

struct NodeIdentIFace
{
    typedef enum { INT, FLOAT, STRING, CHAR, IDENT, SYMBOL } type_t;

    virtual ~NodeIdentIFace()
    {}

    // required
    virtual type_t type() const = 0;
    virtual uint32_t lexer_id() const = 0;
    virtual std::string name() const = 0;
    virtual void set_parent(NodeIdentIFace* parent) = 0;
    virtual NodeIdentIFace* parent() const = 0;
    virtual std::string uid() const = 0;

    // optional
    virtual void detach()
    {}
    virtual int index() const
    {
        return -1;
    }
    virtual NodeIdentIFace* clone(TreeContext* tc) const
    {
        return NULL;
    }
    virtual bool compare(const NodeIdentIFace* _node) const
    {
        return false;
    }
    virtual void set_original(const NodeIdentIFace* original)
    {}
    virtual const NodeIdentIFace* original() const
    {
        return NULL;
    }

    // built-in (part of interface)
    bool is_same_type(const NodeIdentIFace* _node) const
    {
        return type() == _node->type() && lexer_id() == _node->lexer_id();
    }
    bool is_root() const
    {
        return parent() == NULL;
    }
};

template<NodeIdentIFace::type_t>
struct TermInternalType;
template<> struct TermInternalType<NodeIdentIFace::INT>    { typedef long type; };
template<> struct TermInternalType<NodeIdentIFace::FLOAT>  { typedef float32_t type; };
template<> struct TermInternalType<NodeIdentIFace::STRING> { typedef std::string* type; };
template<> struct TermInternalType<NodeIdentIFace::CHAR>   { typedef char type; };
template<> struct TermInternalType<NodeIdentIFace::IDENT>  { typedef const std::string* type; };
template<> struct TermInternalType<NodeIdentIFace::SYMBOL> { typedef NodeIdentIFace* type; };

template<class T>
struct TermType;
template<> struct TermType<long>               { enum { type = NodeIdentIFace::INT}; };
template<> struct TermType<float32_t>          { enum { type = NodeIdentIFace::FLOAT}; };
template<> struct TermType<std::string*>       { enum { type = NodeIdentIFace::STRING}; };
template<> struct TermType<char>               { enum { type = NodeIdentIFace::CHAR}; };
template<> struct TermType<const std::string*> { enum { type = NodeIdentIFace::IDENT}; };
template<> struct TermType<NodeIdentIFace*>    { enum { type = NodeIdentIFace::SYMBOL}; };

template<NodeIdentIFace::type_t T>
struct TermNodeIFace : virtual public NodeIdentIFace
{
    virtual ~TermNodeIFace()
    {}
    virtual typename TermInternalType<T>::type value() const = 0;
};

struct SymbolNodeIFace : virtual public NodeIdentIFace
{
    virtual ~SymbolNodeIFace()
    {}

    // required
    virtual NodeIdentIFace* operator[](uint32_t index) const = 0;
    virtual size_t size() const = 0;

    // optional
    virtual NodeIdentIFace* find(const NodeIdentIFace* _node) const
    {
        return NULL;
    }
    virtual void push_back(NodeIdentIFace* _node)
    {}
    virtual void push_front(NodeIdentIFace* _node)
    {}
    virtual void insert_after(NodeIdentIFace* insert_after_node, NodeIdentIFace* new_node)
    {}
    virtual void remove_first(NodeIdentIFace* _node)
    {}
    virtual void replace_first(NodeIdentIFace* find_node, NodeIdentIFace* replacement_node)
    {}
    virtual void erase(int index)
    {}
    virtual NodeIdentIFace* find_if(bool (*pred)(const NodeIdentIFace* _node)) const
    {
        return NULL;
    }
};

} }

#endif
