#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#debug
#set -x


ls -la
echo -e "TEST"
lsb_relase -a || >&2
echo -e "Next command \n" 

ll /tmp/ || echo -e "command failed to run " >&2
