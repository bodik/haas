#!/bin/sh
set -e

virtualenv --python=python3 cowrie-env
. cowrie-env/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements.txt
pip install mysqlclient
touch cowrie-env/build-finished
