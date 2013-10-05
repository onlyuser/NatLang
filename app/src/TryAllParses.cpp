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

#include "TryAllParses.h"
#include "NatLang.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "NatLang.tab.h" // ID_XXX (yacc generated)
#include "XLangAlloc.h" // Allocator
#include "XLangString.h" // xl::tokenize
#include "XLangSystem.h" // xl::system::shell_capture
#include <vector> // std::vector
#include <list> // std::list
#include <stack> // std::stack
#include <string> // std::string
#include <algorithm> // std::sort
#include <iostream> // std::cerr

typedef std::vector<std::pair<std::string, int>> pos_value_faml_tuples_t;
struct pos_value_faml_tuples_greater_than
{
    bool operator()(
            const pos_value_faml_tuples_t::value_type& x,
            const pos_value_faml_tuples_t::value_type& y) const
    {
        return x.second > y.second;
    }
};

bool get_pos_values_from_wordnet(
        std::string               word,
        std::vector<std::string>* pos_values)
{
    if(word.empty() || !pos_values)
        return false;
    std::string which_wn_stdout = xl::system::shell_capture("which wn");
    if(which_wn_stdout.empty())
    {
        std::cerr << "ERROR: WordNet not found" << std::endl;
        return false;
    }
    pos_value_faml_tuples_t pos_value_faml_tuples;
    bool found_match = false;
    const char* wordnet_faml_types[] = {"n", "v", "a", "r"};
    const char* pos_values_arr[]     = {"Noun", "Verb", "Adj", "Adv"};
    for(int i = 0; i<4; i++)
    {
        std::string wordnet_stdout =
                xl::system::shell_capture("wn \"" + word + "\" -faml" + wordnet_faml_types[i]);
        if(wordnet_stdout.empty())
            continue;
        std::string word_base_form;
        xl::match_regex(wordnet_stdout, "Familiarity of ([^ ]+) ([^ \n]+)", 3,
                NULL,
                NULL,
                &word_base_form);
        if(word_base_form != word)
            found_match |= get_pos_values_from_wordnet(word_base_form, pos_values);
        std::string polysemy_count_str;
        xl::match_regex(wordnet_stdout, "[\(]polysemy count = ([0-9]+)[)]", 2,
                NULL,
                &polysemy_count_str);
        int polysemy_count = atoi(polysemy_count_str.c_str());
        pos_value_faml_tuples.push_back(
                pos_value_faml_tuples_t::value_type(pos_values_arr[i], polysemy_count));
        found_match = true;
    }
    std::sort(pos_value_faml_tuples.begin(), pos_value_faml_tuples.end(),
            pos_value_faml_tuples_greater_than());
    for(auto p = pos_value_faml_tuples.begin(); p != pos_value_faml_tuples.end(); p++)
        pos_values->push_back((*p).first);
    return found_match;
}

bool get_pos_values_from_lexer(
        std::string               word,
        std::vector<std::string>* pos_values,
        std::string               group)
{
    if(word.empty() || !pos_values)
        return false;
    std::string pos_value;
    // whitespace is intentional end-of-word delimiter
    const char eow[] = " ";
    std::string word_alt = std::string("[") + group + "]<" + word + eow + ">";
    try
    {
        uint32_t lexer_id = quick_lex(word_alt.c_str());
        if(lexer_id)
            pos_value = id_to_name(lexer_id);
    }
    catch(const char* s)
    {
        std::cerr << "ERROR: " << s << std::endl;
        return false;
    }
    if(pos_value.empty())
        return false;
    pos_values->push_back(pos_value);
    return true;
}

bool get_pos_values(
        std::string               word,
        std::vector<std::string>* pos_values)
{
    if(word.empty() || !pos_values)
        return false;
    if(word == ".")
    {
        pos_values->push_back("$");
        return true;
    }
    std::set<std::string> unique_pos_values;
    // lookup POS in WordNet and use familiarity score for POS ranking
    {
        std::vector<std::string> pos_values_from_wordnet;
        if(get_pos_values_from_wordnet(word, &pos_values_from_wordnet))
        {
            for(auto q = pos_values_from_wordnet.begin(); q != pos_values_from_wordnet.end(); q++)
            {
                if(unique_pos_values.find(*q) != unique_pos_values.end())
                    continue;
                pos_values->push_back(*q);
                unique_pos_values.insert(*q);
            }
        }
    }
    // lookup POS in lexer hard coded categorizations in case WordNet missed it
    {
        std::vector<std::string> pos_values_from_lexer;
        bool found_match = false;
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer);
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "noun");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "verb");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "adj");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "adv");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "suffix_noun");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "suffix_verb");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "suffix_adj");
        found_match |= get_pos_values_from_lexer(word, &pos_values_from_lexer, "suffix_adv");
        if(found_match)
        {
            for(auto p = pos_values_from_lexer.begin(); p != pos_values_from_lexer.end(); p++)
            {
                if(unique_pos_values.find(*p) != unique_pos_values.end())
                    continue;
                pos_values->push_back(*p);
                unique_pos_values.insert(*p);
                // consider conjugations at the NP/VP/CS level
                if(*p == "Conj")
                {
                    pos_values->push_back("Conj_VP");
                    pos_values->push_back("Conj_CS");
                    unique_pos_values.insert("Conj_VP");
                    unique_pos_values.insert("Conj_CS");
                }
                if(*p == "Prep")
                {
                    pos_values->push_back("Prep_VP");
                    unique_pos_values.insert("Prep_VP");
                }
            }
        }
    }
    if(pos_values->empty())
        pos_values->push_back("Noun"); // if we don't recognize it, it's a noun
    return true;
}

void build_pos_paths_from_pos_options(
        std::list<std::vector<int>>*                 pos_paths,                  // OUT
        const std::vector<std::vector<std::string>> &sentence_pos_options_table, // IN
        std::stack<int>*                             pos_path,                   // TEMP
        int                                          word_index)                 // TEMP
{
    if(!pos_paths || !pos_path)
        return;
    if(static_cast<size_t>(word_index) >= sentence_pos_options_table.size())
    {
        size_t n = pos_path->size();
        std::vector<int> pos_path_vec(n);
        for(int i = 0; i < static_cast<int>(n); i++)
        {
            pos_path_vec[n-i-1] = pos_path->top();
            pos_path->pop();
        }
        pos_paths->push_back(pos_path_vec);
        for(auto q = pos_path_vec.begin(); q != pos_path_vec.end(); q++)
            pos_path->push(*q);
        return;
    }
    const std::vector<std::string> &word_pos_options = sentence_pos_options_table[word_index];
    int pos_index = 0;
    for(auto p = word_pos_options.begin(); p != word_pos_options.end(); p++)
    {
        pos_path->push(pos_index);
        build_pos_paths_from_pos_options(
                pos_paths,
                sentence_pos_options_table,
                pos_path,
                word_index+1);
        pos_path->pop();
        pos_index++;
    }
}

void build_pos_paths_from_pos_options(
        std::list<std::vector<int>>*                 pos_paths,                  // OUT
        const std::vector<std::vector<std::string>> &sentence_pos_options_table) // IN
{
    if(!pos_paths)
        return;
    std::stack<int> pos_path;
    int word_index = 0;
    build_pos_paths_from_pos_options(
            pos_paths,
            sentence_pos_options_table,
            &pos_path,
            word_index);
}

void build_pos_value_paths_from_sentence(
        std::list<std::vector<std::string>>* pos_value_paths, // OUT
        std::string                          sentence)        // IN
{
    if(!pos_value_paths)
        return;
    std::vector<std::vector<std::string>> sentence_pos_options_table;
    std::vector<std::string> words = xl::tokenize(sentence);
    sentence_pos_options_table.resize(words.size());
    int word_index = 0;
    for(auto t = words.begin(); t != words.end(); t++)
    {
        std::cerr << "INFO: " << *t << "<";
        std::vector<std::string> pos_values;
        get_pos_values(*t, &pos_values);
        for(auto r = pos_values.begin(); r != pos_values.end(); r++)
        {
            sentence_pos_options_table[word_index].push_back(*r);
            std::cerr << *r << " ";
        }
        std::cerr << ">" << std::endl;
        word_index++;
    }
    std::list<std::vector<int>> pos_paths;
    build_pos_paths_from_pos_options(&pos_paths, sentence_pos_options_table);
    int path_index = 0;
    for(auto p = pos_paths.begin(); p != pos_paths.end(); p++)
    {
        std::cerr << "INFO: path #" << path_index << ": ";
        std::vector<std::string> pos_value_path;
        int word_index = 0;
        auto pos_indices = *p;
        for(auto q = pos_indices.begin(); q != pos_indices.end(); q++)
        {
            std::string pos_value = sentence_pos_options_table[word_index][*q];
            pos_value_path.push_back(pos_value);
            std::cerr << pos_value << " ";
            word_index++;
        }
        std::cerr << std::endl;
        pos_value_paths->push_back(pos_value_path);
        path_index++;
    }
}

void test_build_pos_value_paths()
{
    std::list<std::vector<std::string>> pos_value_paths;
    build_pos_value_paths_from_sentence(&pos_value_paths, "eats shoots and leaves");
    //test_build_pos_paths("flying saucers are dangerous", pos_paths);
}
