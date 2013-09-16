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

#ifndef XLANG_TREE_CONTEXT_H_
#define XLANG_TREE_CONTEXT_H_

#include "XLangAlloc.h" // Allocator
#include <string> // std::string
#include <set> // std::set

namespace xl { namespace node { class NodeIdentIFace; } }

namespace xl {

class TreeContext
{
public:
    TreeContext(Allocator &alloc)
        : m_alloc(alloc), m_root(NULL)
    {}
    Allocator &alloc() { return m_alloc; }
    node::NodeIdentIFace* &root() { return m_root; }
    const std::string* alloc_unique_string(std::string name);
    std::string* alloc_string(std::string s);

private:
    Allocator &m_alloc;
    node::NodeIdentIFace* m_root; // parse result (parse tree root)

    struct str_ptr_compare_t
    {
        bool operator()(const std::string* s1, const std::string* s2) const
        {
            return *s1 < *s2;
        }
    };
    typedef std::set<std::string*, str_ptr_compare_t> string_set_t;
    string_set_t m_string_set;
};

}

#endif
