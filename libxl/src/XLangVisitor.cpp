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

#include "visitor/XLangVisitor.h" // visitor::Visitor

namespace xl { namespace visitor {

void VisitorDFS::visit(const node::SymbolNodeIFace* _node)
{
    if(m_filter_cb)
    {
        const node::NodeIdentIFace* child = NULL;
        if(next_child(_node, &child))
        {
            do
            {
                if(m_filter_cb(child) && child->type() == node::NodeIdentIFace::SYMBOL)
                {
                    VisitorDFS::visit(dynamic_cast<const node::SymbolNodeIFace*>(child));
                    continue;
                }
                dispatch_visit(child);
            } while(next_child(NULL, &child));
        }
        return;
    }
    if(visit_next_child(_node))
        while(visit_next_child());
}

void VisitorDFS::push_state(const node::SymbolNodeIFace* _node)
{
    m_visit_state_stack.push(visit_state_t(_node, 0));
}

bool VisitorDFS::pop_state()
{
    if(m_visit_state_stack.empty())
        return false;
    m_visit_state_stack.pop();
    return true;
}

bool VisitorDFS::next_state()
{
    if(end_of_visitation())
    {
        pop_state();
        return false;
    }
    m_visit_state_stack.top().second++;
    return true;
}

bool VisitorDFS::get_current_node(const node::NodeIdentIFace** _node) const
{
    if(end_of_visitation())
        return false;
    const visit_state_t &visit_state = m_visit_state_stack.top();
    if(_node)
        *_node = (*visit_state.first)[visit_state.second];
    return true;
}

bool VisitorDFS::end_of_visitation() const
{
    if(m_visit_state_stack.empty())
        return true;
    return m_visit_state_stack.top().second == static_cast<int>(m_visit_state_stack.top().first->size());
}

void VisitorBFS::push_state(const node::SymbolNodeIFace* _node)
{
    m_visit_state_stack.push(visit_state_t());
    m_visit_state_stack.top().push(_node);
}

bool VisitorBFS::pop_state()
{
    if(m_visit_state_stack.empty())
        return false;
    m_visit_state_stack.pop();
    return true;
}

bool VisitorBFS::next_state()
{
    if(end_of_visitation())
    {
        pop_state();
        return false;
    }
    visit_state_t &visit_state = m_visit_state_stack.top();
    const node::NodeIdentIFace* _node = NULL;
    do
    {
        _node = visit_state.front();
        if(_node && _node->type() == node::NodeIdentIFace::SYMBOL)
        {
            auto symbol = dynamic_cast<const node::SymbolNodeIFace*>(_node);
            for(int i = 0; i<static_cast<int>(symbol->size()); i++)
                visit_state.push((*symbol)[i]);
        }
        visit_state.pop();
    } while(m_filter_cb && m_filter_cb(_node) && visit_state.size());
    return true;
}

bool VisitorBFS::get_current_node(const node::NodeIdentIFace** _node) const
{
    if(end_of_visitation())
        return false;
    const visit_state_t &visit_state = m_visit_state_stack.top();
    if(_node)
        *_node = visit_state.front();
    return true;
}

bool VisitorBFS::end_of_visitation() const
{
    if(m_visit_state_stack.empty())
        return true;
    return m_visit_state_stack.top().empty();
}

} }
