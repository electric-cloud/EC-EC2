#
# Makefile responsible for building the EC-EC2 plugin
#
# Copyright (c) 2005-2012 Electric Cloud, Inc.
# All rights reserved

SRCTOP = ..
include $(SRCTOP)/build/vars.mak

build: package
unittest:
systemtest:test-setup test-run

NTESTFILES ?= systemtest

NTESTINCLUDES += -I../../perlapi/lib

TEST_SERVER_PORT ?= 0

test-setup:
	$(EC_PERL) ../EC-EC2/systemtest/setup.pl $(TEST_SERVER) $(PLUGINS_ARTIFACTS) --auxport $(TEST_SERVER_PORT)

test-run: systemtest-run

test: build install promote

include $(SRCTOP)/build/rules.mak
