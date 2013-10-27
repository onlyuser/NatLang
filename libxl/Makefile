# XLang
# -- A parser framework for language modeling
# Copyright (C) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#=======================
# environment variables
#=======================

# INCLUDE_PATH_EXTERN
# LIB_PATH_EXTERN

#==================
# compile flags
#==================

PARENT = ..
INCLUDE_PATH = include
LIB_PATH = lib
LIB_PATH_PARENT = $(PARENT)/lib
SRC_PATH = src
BUILD_PATH = build
BIN_PATH = bin
BINARY = $(BIN_PATH)/libxl.a
INSTALL_BINARY = $(LIB_PATH_PARENT)/libxl.a

INCLUDE_PATHS = $(INCLUDE_PATH) $(INCLUDE_PATH_EXTERN)
INCLUDE_PATH_FLAGS = $(patsubst %, -I%, $(INCLUDE_PATHS))

LIB_PATHS = $(LIB_PATH) $(LIB_PATH_EXTERN)
LIB_PATH_FLAGS = $(patsubst %, -L%, $(LIB_PATHS))

ifdef LIB_PATH_EXTERN
	LIB_STEMS_EXTERN = ticppd
endif
LIB_FLAGS = $(patsubst %, -l%, $(LIB_STEMS_EXTERN))

CXX = g++
DEBUG = -g
CXXFLAGS = -Wall $(DEBUG) $(INCLUDE_PATH_FLAGS) -std=c++0x -D_GNU_SOURCE
ifdef INCLUDE_PATH_EXTERN
	CXXFLAGS := $(CXXFLAGS) -DINCLUDE_PATH_EXTERN
endif
LDFLAGS = -Wall $(DEBUG) $(LIB_PATH_FLAGS) $(LIB_FLAGS) -rdynamic

SCRIPT_PATH = $(PARENT)/scripts

#==================
# all
#==================

.DEFAULT_GOAL : all
all : $(BINARY)

#==================
# objects
#==================

$(BUILD_PATH)/%.o : $(SRC_PATH)/%.cpp
	mkdir -p $(BUILD_PATH)
	$(CXX) -c -o $@ $< $(CXXFLAGS)

.PHONY : clean_objects
clean_objects :
	-rm $(OBJECTS)

#==================
# binary
#==================

CPP_STEMS = \
		XLangAlloc \
		XLangMVCModel \
		XLangMVCView \
		XLangNode \
		XLangPrinter \
		XLangString \
		XLangSystem \
		XLangVisitor \
		XLangTreeContext
OBJECTS = $(patsubst %, $(BUILD_PATH)/%.o, $(CPP_STEMS))
LINT_FILES = $(patsubst %, $(BUILD_PATH)/%.lint, $(CPP_STEMS))

$(BINARY) : $(OBJECTS)
	mkdir -p $(BIN_PATH)
	$(AR) -cvq $@ $^
	mkdir -p $(LIB_PATH_PARENT)
	cp $@ $(INSTALL_BINARY)

.PHONY : clean_binary
clean_binary : clean_objects
	-rm $(BINARY)
	-rm $(INSTALL_BINARY)

#==================
# lint
#==================

LINT_PASS_FILES = $(patsubst %, %.pass, $(LINT_FILES))
LINT_FAIL_FILES = $(patsubst %, %.fail, $(LINT_FILES))
LINT_SH = $(SCRIPT_PATH)/lint.sh

$(BUILD_PATH)/%.lint.pass : $(SRC_PATH)/%.cpp
	mkdir -p $(BUILD_PATH)
	-$(LINT_SH) $< $(BUILD_PATH)/$*.lint $(INCLUDE_PATH_FLAGS)

.PHONY : lint
lint : $(LINT_PASS_FILES)

.PHONY : clean_lint
clean_lint :
	-rm $(LINT_PASS_FILES) $(LINT_FAIL_FILES)

#==================
# doc
#==================

DOC_PATH = $(PARENT)/doc
DOC_CONFIG_FILE = XLang.config
DOC_CONFIG_PATCH_FILE = $(DOC_CONFIG_FILE).patch
DOC_TOOL = doxygen

.PHONY : doc
doc :
	mkdir -p $(BUILD_PATH)
	doxygen -g $(BUILD_PATH)/$(DOC_CONFIG_FILE)
	patch $(BUILD_PATH)/$(DOC_CONFIG_FILE) < $(DOC_PATH)/$(DOC_CONFIG_PATCH_FILE)
	cd $(BUILD_PATH); $(DOC_TOOL) $(DOC_CONFIG_FILE)

.PHONY : clean_doc
clean_doc :
	rm -rf $(BUILD_PATH)/html
	rm -rf $(BUILD_PATH)/$(DOC_CONFIG_FILE)

#==================
# clean
#==================

.PHONY : clean
clean : clean_binary clean_lint clean_doc
	-rmdir $(BUILD_PATH) $(BIN_PATH)
