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

#ifndef XLANG_FILTERABLE_H_
#define XLANG_FILTERABLE_H_

#include "node/XLangNodeIFace.h" // node::NodeIdentIFace

namespace xl { namespace visitor {

class Filterable
{
public:
    typedef bool (*filter_cb_t)(const node::NodeIdentIFace*);

    Filterable() : m_filter_cb(NULL)
    {}
    virtual ~Filterable()
    {}
    void set_filter_cb(filter_cb_t filter_cb)
    {
        m_filter_cb = filter_cb;
    }

protected:
    filter_cb_t m_filter_cb;
};

} }

#endif
