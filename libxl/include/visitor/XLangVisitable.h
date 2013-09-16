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

#ifndef XLANG_VISITABLE_H_
#define XLANG_VISITABLE_H_

#include "visitor/XLangVisitorIFace.h" // visitor::VisitorIFace

namespace xl { namespace visitor {

template<class T>
class Visitable
{
public:
    Visitable(T* instance) : m_instance(instance)
    {}
    virtual ~Visitable()
    {}
    // NOTE: VisitorIFace is non-const to allow mutable visitor state
    virtual void accept(VisitorIFace<T>* v)
    {
        // "Java Tip 98" from http://en.wikipedia.org/wiki/VisitorIFace_pattern
        v->dispatch_visit(m_instance);
    }

private:
    T* m_instance;
};

} }

#endif
