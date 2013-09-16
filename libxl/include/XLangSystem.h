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

#ifndef XLANG_SYSTEM_H_
#define XLANG_SYSTEM_H_

#include <signal.h> // siginfo_t
#include <string> // std::string

namespace xl { namespace system {

typedef void (*sa_sigaction_t)(int, siginfo_t*, void*);

std::string get_execname();
std::string shell_capture(std::string cmd);
std::string get_basename(std::string filename);
void backtrace_sighandler(int sig, siginfo_t* info, void* secret);
void gdb_sighandler(int sig, siginfo_t* info, void* secret);
void add_sighandler(int sig, sa_sigaction_t _sa_sigaction);

} }

#endif
