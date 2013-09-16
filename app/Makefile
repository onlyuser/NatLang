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
SRC_PATH = src
BUILD_PATH = build
BIN_PATH = bin
BINARY = $(BIN_PATH)/XLang

COMMON = $(PARENT)/libxl
INCLUDE_PATH_COMMON = $(COMMON)/include
SRC_PATH_COMMON = $(COMMON)/src
BUILD_PATH_COMMON = $(BUILD_PATH)/libxl

INCLUDE_PATHS = $(INCLUDE_PATH) $(INCLUDE_PATH_COMMON) $(INCLUDE_PATH_EXTERN)
INCLUDE_PATH_FLAGS = $(patsubst %, -I%, $(INCLUDE_PATHS))

LIB_PATHS = $(LIB_PATH) $(LIB_PATH_PARENT) $(LIB_PATH_EXTERN)
LIB_PATH_FLAGS = $(patsubst %, -L%, $(LIB_PATHS))

LIB_STEMS_PARENT = #xl
ifdef LIB_PATH_EXTERN
	LIB_STEMS_EXTERN = ticppd
endif
LIB_FLAGS = \
		$(patsubst %, -l%, $(LIB_STEMS_PARENT)) \
		$(patsubst %, -l%, $(LIB_STEMS_EXTERN))

CXX = g++
DEBUG = -g
CXXFLAGS = -Wall $(DEBUG) $(INCLUDE_PATH_FLAGS) -std=c++0x
ifdef INCLUDE_PATH_EXTERN
	CXXFLAGS := $(CXXFLAGS) -DINCLUDE_PATH_EXTERN
endif
LDFLAGS = -Wall $(DEBUG) $(LIB_PATH_FLAGS) $(LIB_FLAGS)

SCRIPT_PATH = $(PARENT)/scripts
TEST_PATH = $(PARENT)/tests

#==================
# all
#==================

.DEFAULT_GOAL : all
all : $(BINARY)

#==================
# yacc-gen
#==================

YACC_STEMS = XLang.tab
YACC_GEN = \
		$(patsubst %, $(SRC_PATH)/%.cpp, $(YACC_STEMS)) \
		$(patsubst %, $(INCLUDE_PATH)/%.h, $(YACC_STEMS))
.SECONDARY : $(YACC_GEN)

$(SRC_PATH)/%.tab.cpp $(INCLUDE_PATH)/%.tab.h : $(SRC_PATH)/%.y
	bison -d $<
	mv $*.tab.c $(SRC_PATH)/$*.tab.cpp
	mv $*.tab.h $(INCLUDE_PATH)/$*.tab.h

.PHONY : clean_yacc
clean_yacc :
	-rm $(YACC_GEN)

#==================
# lex-gen
#==================

LEX_STEMS = lex.XLang
LEX_GEN = $(patsubst %, $(SRC_PATH)/%.cpp, $(LEX_STEMS))
.SECONDARY : $(LEX_GEN)

$(SRC_PATH)/lex.%.cpp : $(SRC_PATH)/%.l $(YACC_GEN)
	flex $<
	mv lex.$*.c $(SRC_PATH)/lex.$*.cpp

.PHONY : clean_lex
clean_lex :
	-rm $(LEX_GEN)

#==================
# objects (common)
#==================

CPP_STEMS_COMMON = \
		XLangAlloc \
		XLangMVCView \
		XLangPrinter \
		XLangString \
		XLangSystem \
		XLangVisitorDFS \
		XLangTreeContext #\
		XLangMVCModel \
		XLangNode
OBJECTS_COMMON = $(patsubst %, $(BUILD_PATH_COMMON)/%.o, $(CPP_STEMS_COMMON))
LINT_FILES_COMMON = $(patsubst %, $(BUILD_PATH_COMMON)/%.lint, $(CPP_STEMS_COMMON))

$(BUILD_PATH_COMMON)/%.o : $(SRC_PATH_COMMON)/%.cpp
	mkdir -p $(BUILD_PATH_COMMON)
	$(CXX) -c -o $@ $< $(CXXFLAGS)

.PHONY : clean_objects_common
clean_objects_common :
	-rm $(OBJECTS_COMMON)
	-rmdir $(BUILD_PATH_COMMON)

#==================
# objects
#==================

$(BUILD_PATH)/%.o : $(SRC_PATH)/%.cpp
	mkdir -p $(BUILD_PATH)
	$(CXX) -c -o $@ $< $(CXXFLAGS)

.PHONY : clean_objects
clean_objects : clean_objects_common clean_yacc clean_lex
	-rm $(OBJECTS)

#==================
# binary
#==================

CPP_STEMS = $(YACC_STEMS) $(LEX_STEMS) TryAllParses XLangMVCModel XLangNode
OBJECTS = $(patsubst %, $(BUILD_PATH)/%.o, $(CPP_STEMS))
LINT_FILES = $(patsubst %, $(BUILD_PATH)/%.lint, $(CPP_STEMS))

$(BINARY) : $(OBJECTS) $(OBJECTS_COMMON)
	mkdir -p $(BIN_PATH)
	$(CXX) -o $@ $^ $(LDFLAGS)

.PHONY : clean_binary
clean_binary : clean_objects
	-rm $(BINARY)

#==================
# test
#==================

.PHONY : test
test : $(BINARY)
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) BINARY=$(abspath $(BINARY)) INPUT_MODE="arg" \
			BASIC_SUITE=1

.PHONY : clean_test
clean_test :
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) \
			BASIC_SUITE=1

#==================
# import
#==================

.PHONY : import
import : $(BINARY)
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) BINARY=$(abspath $(BINARY)) INPUT_MODE="xml" \
			BASIC_SUITE=1

.PHONY : clean_import
clean_import :
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) \
			BASIC_SUITE=1

#==================
# pure
#==================

.PHONY : pure
pure : $(BINARY)
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) BINARY=$(abspath $(BINARY)) INPUT_MODE="arg" \
			BASIC_SUITE=1

.PHONY : clean_pure
clean_pure :
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) \
			BASIC_SUITE=1

#==================
# dot
#==================

.PHONY : dot
dot : $(BINARY)
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) BINARY=$(abspath $(BINARY)) INPUT_MODE="arg" \
			BASIC_SUITE=1

.PHONY : clean_dot
clean_dot :
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) \
			BASIC_SUITE=1

#==================
# xml
#==================

.PHONY : xml
xml : $(BINARY)
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) BINARY=$(abspath $(BINARY)) INPUT_MODE="arg" \
			BASIC_SUITE=1

.PHONY : clean_xml
clean_xml :
	cd $(TEST_PATH); $(MAKE) $@ \
			BUILD_PATH=$(abspath $(BUILD_PATH)) \
			BASIC_SUITE=1

#==================
# lint (common)
#==================

LINT_PASS_FILES_COMMON = $(patsubst %, %.pass, $(LINT_FILES_COMMON))
LINT_FAIL_FILES_COMMON = $(patsubst %, %.fail, $(LINT_FILES_COMMON))

$(BUILD_PATH_COMMON)/%.lint.pass : $(SRC_PATH_COMMON)/%.cpp
	mkdir -p $(BUILD_PATH_COMMON)
	-$(LINT_SH) $(LINT_TOOL) $< $(BUILD_PATH_COMMON)/$*.lint $(LINTFLAGS)

.PHONY : lint_common
lint_common : $(LINT_PASS_FILES_COMMON)

.PHONY : clean_lint_common
clean_lint_common :
	-rm $(LINT_PASS_FILES_COMMON) $(LINT_FAIL_FILES_COMMON)

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
lint : $(LINT_PASS_FILES) lint_common

.PHONY : clean_lint
clean_lint : clean_lint_common
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
clean : clean_binary clean_test clean_import clean_pure clean_dot clean_xml clean_lint clean_doc
	-rmdir $(BUILD_PATH) $(BIN_PATH)
