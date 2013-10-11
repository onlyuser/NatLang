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

#include "XLangSystem.h" // xl::system::add_sighandler
#include "XLangString.h" // xl::regexp
#include <stdio.h> // FILE
#include <stdlib.h> // free
#include <string.h> // strdup
#include <iostream> // std::cerr
#include <unistd.h> // getpid
#include <iomanip> // std::setfill
#include <string> // std::string
#include <vector> // std::vector
#include <sstream> // std::stringstream
#include <execinfo.h> // backtrace_symbols
#include <ucontext.h> // ucontext_t
#include <cxxabi.h> // abi::__cxa_demangle
#include <sys/wait.h> // waitpid
#include <bits/signum.h> // SIGSEGV

//#define DEBUG

#ifdef __x86_64__
    #define REG_EIP REG_RIP
#endif

#define MAX_EXECNAME_SIZE   1024
#define MAX_PIPEBUF_SIZE    128
#define MAX_BACKTRACE_DEPTH 16
#define LIBC_START_MAIN     "__libc_start_main"

namespace xl { namespace system {

std::string get_execname()
{
    static std::string execname;
    if(execname.size())
        return execname;
    char buf[MAX_EXECNAME_SIZE];
    int n = readlink("/proc/self/exe", buf, sizeof(buf)-1);
    if(n == -1)
        return "";
    buf[n] = '\0';
    execname = buf;
    return execname;
}

std::string shell_capture(std::string cmd)
{
    FILE* file = popen(cmd.c_str(), "r");
    if(!file)
        return "";
    char buf[MAX_PIPEBUF_SIZE];
    std::string result = "";
    while(!feof(file))
    {
        if(fgets(buf, sizeof(buf), file))
            result += buf;
    }
    pclose(file);
    return result.substr(0, result.length()-1);
}

std::string get_basename(std::string filename)
{
    std::string _basename;
    char* buf = strdup(filename.c_str());
    _basename = basename(buf);
    free(buf);
    return _basename;
}

void backtrace_sighandler(int sig, siginfo_t* info, void* secret)
{
    std::cerr << "stack array for " << get_execname() << " pid=" << getpid() << std::endl
            << "Error: signal " << sig << ":" << std::endl;
    void* array[MAX_BACKTRACE_DEPTH];
    int size = backtrace(array, MAX_BACKTRACE_DEPTH);
    array[1] = reinterpret_cast<void*>(
            reinterpret_cast<ucontext_t*>(secret)->uc_mcontext.gregs[REG_EIP]);
    char** symbols = backtrace_symbols(array, size);
    for(int i = 1; i<size; i++)
    {
        std::stringstream ss;
        ss << "addr2line " << array[i] << " -e " << get_execname();
        std::string execname = shell_capture(ss.str());
        std::string exec_basename = get_basename(execname);
        std::string module, mangled_name, offset, address;
        std::string symbol(symbols[i]);
        if(regexp(symbol, "([^ ]+)[\(]([^ ]+)[+]([^ ]+)[)] [\[]([^ ]+)[]]", 5,
                NULL,
                &module,
                &mangled_name,
                &offset,
                &address))
        {
            // addr2line output format: "module(mangled_name+offset) [address]"
            if(mangled_name == LIBC_START_MAIN)
                break;
            int status;
            char* demangled_name = abi::__cxa_demangle(mangled_name.c_str(), NULL, 0, &status);
            if(status == 0)
            {
                std::cerr << "#" << i
                        << "  0x" << std::setfill('0') << std::setw(16) << std::hex
                        << reinterpret_cast<size_t>(array[i])
                        << " in " << demangled_name << " at " << exec_basename << std::endl;
                free(demangled_name);
            }
            else
            {
                std::cerr << "#" << i
                        << "  0x" << std::setfill('0') << std::setw(16) << std::hex
                        << reinterpret_cast<size_t>(array[i])
                        << " in " << mangled_name << " at " << exec_basename << std::endl;
            }
        }
        else if(regexp(symbol, "([^ ]+)[\(][)] [\[]([^ ]+)[]]", 3,
                NULL,
                &module,
                &address))
        {
            // addr2line output format: "module() [address]"
            std::cerr << "#" << i
                    << "  0x" << std::setfill('0') << std::setw(16) << std::hex
                    << reinterpret_cast<size_t>(array[i])
                    << " in ?? at " << exec_basename << std::endl;
        }
        else
            std::cerr << "#" << i << "  " << symbol << std::endl;
    }
    free(symbols);
    exit(0);
}

void gdb_sighandler(int sig, siginfo_t* info, void* secret)
{
    std::stringstream ss;
    ss << getpid();
    std::string pid_str = ss.str();
    int child_pid = fork();
    if(!child_pid)
    {
        std::string execname = get_execname();
        execlp("gdb",
                "-n",             // skip .gdbinit
                "-ex", "bt",      // show backtrace
                "-ex", "thread",  // show current thread info
                execname.c_str(), // exec name
                pid_str.c_str(),  // process id
                NULL);
        abort();
    }
    else
        waitpid(child_pid, NULL, 0);
    exit(0);
}

void add_sighandler(int sig, sa_sigaction_t _sa_sigaction)
{
    struct sigaction sa;
    sa.sa_sigaction = _sa_sigaction;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART|SA_SIGINFO;
    sigaction(sig, &sa, NULL);
}

} }
