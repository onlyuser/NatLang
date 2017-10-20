# NatLang
# -- An English parser with an extensible grammar
# Copyright (C) 2011 onlyuser <mailto:onlyuser@gmail.com>
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

#==================
# external defines
#==================

# BUILD_PATH
# BINARY
# INPUT_MODE

#==================
# compile flags
#==================

PARENT = ..
SCRIPT_PATH = $(PARENT)/scripts

TEST_REGEX_ENABLE = ""
TEST_REGEX_DISABLE = "phony_regex_should_never_occur"
ifneq ($(strip $(BASIC_SUITE)),)
	TEST_PATH = basic_suite
endif
TEST_FILE_STEMS = \
		$(shell \
				find $(TEST_PATH) -mindepth 1 -maxdepth 1 -name "*" -type f | sort \
						| xargs -I@ basename @ \
						| cut -d. -f1 | uniq \
						| grep    "$(TEST_REGEX_ENABLE)" \
						| grep -v "$(TEST_REGEX_DISABLE)" \
				)
OUT_PREFIX = $(TEST_PATH)

#==================
# all
#==================

.DEFAULT_GOAL : all
all : test

#==================
# test
#==================

TEST_FILES = $(patsubst %, $(BUILD_PATH)/$(OUT_PREFIX).%.test, $(TEST_FILE_STEMS))
TEST_PASS_FILES = $(patsubst %, %.pass, $(TEST_FILES))
TEST_FAIL_FILES = $(patsubst %, %.fail, $(TEST_FILES))
TEST_SH := $(SCRIPT_PATH)/test.sh

$(BUILD_PATH)/$(OUT_PREFIX).%.test.pass : $(BINARY) $(TEST_PATH)/%.test
	-$(TEST_SH) $(BINARY) \
			--lisp__--skip_singleton \
			$(INPUT_MODE) \
			$(TEST_PATH)/$*.test \
			$(TEST_PATH)/$*.gold \
			$(BUILD_PATH)/$(OUT_PREFIX).$*.test

.PHONY : test
test : $(TEST_PASS_FILES)

.PHONY : clean_test
clean_test :
	-rm $(TEST_PASS_FILES) $(TEST_FAIL_FILES)

#==================
# import
#==================

IMPORT_FILES = $(patsubst %, $(BUILD_PATH)/$(OUT_PREFIX).%.import, $(TEST_FILE_STEMS))
IMPORT_PASS_FILES = $(patsubst %, %.pass, $(IMPORT_FILES))
IMPORT_FAIL_FILES = $(patsubst %, %.fail, $(IMPORT_FILES))
TEST_SH := $(SCRIPT_PATH)/test.sh

$(BUILD_PATH)/$(OUT_PREFIX).%.import.pass : $(BINARY) $(TEST_PATH)/%.import.test-gold
	-$(TEST_SH) $(BINARY) \
			--xml \
			$(INPUT_MODE) \
			$(TEST_PATH)/$*.import.test-gold \
			$(TEST_PATH)/$*.import.test-gold \
			$(BUILD_PATH)/$(OUT_PREFIX).$*.import

.PHONY : import
import : $(IMPORT_PASS_FILES)

.PHONY : clean_import
clean_import :
	-rm $(IMPORT_PASS_FILES) $(IMPORT_FAIL_FILES)

#==================
# pure
#==================

PURE_FILES = $(patsubst %, $(BUILD_PATH)/$(OUT_PREFIX).%.pure, $(TEST_FILE_STEMS))
PURE_PASS_FILES = $(patsubst %, %.pass, $(PURE_FILES))
PURE_FAIL_FILES = $(patsubst %, %.fail, $(PURE_FILES))
GOLD_KEYWORD = "All heap blocks were freed -- no leaks are possible"
PURE_SH = $(SCRIPT_PATH)/pure.sh

$(BUILD_PATH)/$(OUT_PREFIX).%.pure.pass : $(BINARY) $(TEST_PATH)/%.test
	-$(PURE_SH) $(BINARY) \
			$(INPUT_MODE) \
			$(TEST_PATH)/$*.test \
			$(GOLD_KEYWORD) \
			$(BUILD_PATH)/$(OUT_PREFIX).$*.pure

.PHONY : pure
pure : $(PURE_PASS_FILES)

.PHONY : clean_pure
clean_pure :
	-rm $(PURE_PASS_FILES) $(PURE_FAIL_FILES)

#==================
# dot
#==================

DOT_FILES = $(patsubst %, $(BUILD_PATH)/$(OUT_PREFIX).%.dot, $(TEST_FILE_STEMS))
DOT_PNG_FILES = $(patsubst %, %.png, $(DOT_FILES))
EXPORT_SH := $(SCRIPT_PATH)/export.sh

$(BUILD_PATH)/$(OUT_PREFIX).%.dot.png : $(BINARY) $(TEST_PATH)/%.test
	-$(EXPORT_SH) $(BINARY) \
			$(INPUT_MODE) \
			$(TEST_PATH)/$*.test \
			png \
			$(BUILD_PATH)/$(OUT_PREFIX).$*.dot

.PHONY : dot
dot : $(DOT_PNG_FILES)

.PHONY : clean_dot
clean_dot :
	-rm $(DOT_FILES) $(DOT_PNG_FILES)

#==================
# xml
#==================

XML_FILES = $(patsubst %, $(BUILD_PATH)/$(OUT_PREFIX).%.xml, $(TEST_FILE_STEMS))
EXPORT_SH := $(SCRIPT_PATH)/export.sh

$(BUILD_PATH)/$(OUT_PREFIX).%.xml : $(BINARY) $(TEST_PATH)/%.test
	-$(EXPORT_SH) $(BINARY) \
			$(INPUT_MODE) \
			$(TEST_PATH)/$*.test \
			xml \
			$(BUILD_PATH)/$(OUT_PREFIX).$*

.PHONY : xml
xml : $(XML_FILES)

.PHONY : clean_xml
clean_xml :
	-rm $(XML_FILES)

#==================
# clean
#==================

.PHONY : clean
clean : clean_test clean_import clean_pure clean_dot clean_xml
