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

#ifndef XLANG_ALLOC_H_
#define XLANG_ALLOC_H_

#include <map> // std::map
#include <string> // std::string
#include <stddef.h> // size_t
#include <list> // std::list

#define DTOR_CB(ns, c) [](void* x) {      \
        reinterpret_cast<ns c*>(x)->~c(); \
        }
#define DTOR_CB_EX(ns, c, f) [](void* x) { \
        reinterpret_cast<ns c*>(x)->~f();  \
        }

#define PNEW_LOC(a) \
        (a), __FILE__, __LINE__

#define PNEW(a, ns, c) \
        PNEW_LOC(a), DTOR_CB(ns, c)
#define PNEW_EX(a, ns, c, f) \
        PNEW_LOC(a), DTOR_CB_EX(ns, c, f)

namespace xl {

class MemChunk
{
public:
    typedef void (*dtor_cb_t)(void*);

    MemChunk(size_t _size_bytes, std::string _filename, size_t _line_number, dtor_cb_t dtor_cb = NULL);
    ~MemChunk();
    void* ptr() const { return m_ptr; }
    size_t size() const { return m_size_bytes; }
    std::string filename() const { return m_filename; }
    size_t line_number() const { return m_line_number; }
    void dump(std::string indent) const;

private:
    size_t m_size_bytes;
    std::string m_filename;
    size_t m_line_number;
    dtor_cb_t m_dtor_cb;
    void* m_ptr;
};

class Allocator
{
public:
    Allocator(std::string _filename);
    ~Allocator();
    std::string name() const { return m_name; }
    size_t size() const { return m_size_bytes; }
    void* _malloc(size_t size_bytes, std::string filename, size_t line_number, MemChunk::dtor_cb_t dtor_cb = NULL);
    void _free(void* ptr);
    void _free();
    void dump(std::string indent) const;

private:
    typedef std::map<void*, MemChunk*> internal_type_t;
    std::string m_name;
    internal_type_t m_chunk_map;
    size_t m_size_bytes;
};

}

// NOTE: doesn't work for arrays
void* operator new(size_t size_bytes, xl::Allocator &alloc, std::string filename, size_t line_number,
        xl::MemChunk::dtor_cb_t dtor_cb);
void* operator new(size_t size_bytes, xl::Allocator &alloc, std::string filename, size_t line_number);

#endif
