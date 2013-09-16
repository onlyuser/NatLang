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

#include "XLangTreeContext.h" // TreeContext
#include <string> // std::string

namespace xl {

std::string* TreeContext::alloc_string(std::string s)
{
    return new (PNEW_EX(m_alloc, std::, string, basic_string))
            std::string(s);
}

const std::string* TreeContext::alloc_unique_string(std::string name)
{
    auto p = m_string_set.find(&name);
    if(p == m_string_set.end())
    {
        m_string_set.insert(new (PNEW_EX(m_alloc, std::, string, basic_string))
                std::string(name));
        p = m_string_set.find(&name);
    }
    return *p;
}

}
