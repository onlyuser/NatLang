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

#include "XLangAlloc.h" // Allocator
#include <string> // std::string
#include <iostream> // std::cout
#include <stdlib.h> // malloc
#include <stddef.h> // size_t

namespace xl {

MemChunk::MemChunk(size_t _size_bytes, std::string _filename, size_t _line_number, dtor_cb_t dtor_cb)
    : m_size_bytes(_size_bytes), m_filename(_filename), m_line_number(_line_number), m_dtor_cb(dtor_cb)
{
    m_ptr = malloc(_size_bytes);
}

MemChunk::~MemChunk()
{
    if(m_ptr)
    {
        if(m_dtor_cb)
            m_dtor_cb(m_ptr);
        free(m_ptr);
    }
}

void MemChunk::dump(std::string indent) const
{
    std::cout << indent << m_filename << ":" << m_line_number << " .. " << m_size_bytes << " bytes";
}

Allocator::Allocator(std::string name)
    : m_name(name), m_size_bytes(0)
{
}
Allocator::~Allocator()
{
    _free();
}

void* Allocator::_malloc(size_t size_bytes, std::string filename, size_t line_number,
        MemChunk::dtor_cb_t dtor_cb)
{
    MemChunk* chunk = new MemChunk(size_bytes, filename, line_number, dtor_cb);
    m_size_bytes += size_bytes;
    m_chunk_map.insert(internal_type_t::value_type(chunk->ptr(), chunk));
    return chunk->ptr();
}

void Allocator::_free(void* ptr)
{
    auto p = m_chunk_map.find(ptr);
    if(p != m_chunk_map.end())
    {
        MemChunk* chunk = (*p).second;
        m_size_bytes -= chunk->size();
        delete chunk;
    }
    m_chunk_map.erase(p);
}

void Allocator::_free()
{
    for(auto p = m_chunk_map.begin(); p != m_chunk_map.end(); ++p)
        delete (*p).second;
    m_chunk_map.clear();
}

void Allocator::dump(std::string indent) const
{
    std::cout << '\"' << m_name << "\" {" << std::endl;
    for(auto p = m_chunk_map.begin(); p != m_chunk_map.end(); ++p)
    {
        (*p).second->dump(indent);
        std::cout << std::endl;
    }
    std::cout << "};" << std::endl;
}

}

void* operator new(size_t size_bytes, xl::Allocator &alloc, std::string filename, size_t line_number,
        xl::MemChunk::dtor_cb_t dtor_cb)
{
    return alloc._malloc(size_bytes, filename, line_number, dtor_cb);
}

void* operator new(size_t size_bytes, xl::Allocator &alloc, std::string filename, size_t line_number)
{
    return alloc._malloc(size_bytes, filename, line_number, NULL);
}
