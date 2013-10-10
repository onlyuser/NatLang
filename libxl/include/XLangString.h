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

#ifndef XLANG_STRING_H_
#define XLANG_STRING_H_

#include <string> // std::string
#include <vector> // std::vector

namespace xl {

bool                     read_file(std::string filename, std::string &s);
std::string              replace(std::string &s, std::string find_string, std::string replace_string);
std::vector<std::string> tokenize(const std::string &s, const char* delim = " ");
std::string              escape_xml(std::string &s);
std::string              unescape_xml(std::string &s);
std::string              escape(std::string &s);
std::string              unescape(std::string &s);
std::string              escape(char c);
char                     unescape(char c);

bool regex(std::string &s, std::string pattern, int nmatch, ...);

}

#endif
