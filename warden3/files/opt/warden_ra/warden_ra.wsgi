#!/usr/bin/python
# -*- coding: utf-8 -*-

from sys import path
from os.path import dirname, join

path.append(dirname(__file__))
from warden_ra import build_server

## JSON configuration with line comments (trailing #)
from warden_ra import read_cfg
application = build_server(read_cfg(join(dirname(__file__), "warden_ra.cfg")))
