#!/usr/bin/python

from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime
from math import trunc
from uuid import uuid4
from pprint import pprint
from os import path
from random import randint, randrange, choice, random;
from base64 import b64encode;
import argparse

def gen_min_idea(client_name):

    return {
       "Format": "IDEA0",
       "ID": str(uuid4()),
       "DetectTime": format_timestamp(),
       "Category": ["Test"],
       "Node": [
          {
             "Name": client_name,
             "Type": ["Log"],
             "SW": ["Tester"]
          }
       ]
    }


def main():

    wclient = Client(**read_cfg("warden_client_tester.cfg"))
    start = time()
    ret = wclient.sendEvents([gen_min_idea(client_name=wclient.name)])
    ret['time'] = (time()-start)
    wclient.logger.info(ret)

if __name__ == "__main__":
    main()
