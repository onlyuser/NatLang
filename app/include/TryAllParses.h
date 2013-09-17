// NatLang
// -- A parser framework for natural language processing
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

#ifndef TRY_ALL_PARSES_H_
#define TRY_ALL_PARSES_H_

#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "XLangAlloc.h" // Allocator
#include <vector> // std::vector
#include <list> // std::list
#include <stack> // std::stack
#include <string> // std::string

bool get_pos_values_from_lexer(
        std::string               word,
        std::vector<std::string>* pos_values);
bool get_pos_values_from_wordnet(
        std::string               word,
        std::vector<std::string>* pos_values);
bool get_pos_values(
        std::string               word,
        std::vector<std::string>* pos_values);
void build_pos_paths_from_pos_options(
        std::list<std::vector<int>>*                 pos_paths,                  // OUT
        const std::vector<std::vector<std::string>> &sentence_pos_options_table, // IN
        std::stack<int>*                             pos_path,                   // TEMP
        int                                          word_index);                // TEMP
void build_pos_paths_from_pos_options(
        std::list<std::vector<int>>*                 pos_paths,                   // OUT
        const std::vector<std::vector<std::string>> &sentence_pos_options_table); // IN
void build_pos_value_paths_from_sentence(
        std::list<std::vector<std::string>>* pos_value_paths, // OUT
        std::string                          sentence);       // IN
void test_build_pos_value_paths();

#endif
