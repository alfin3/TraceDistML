#!/bin/bash

# sets up tracing

set -e

pip install opentracing

apt-get -y update 
apt-get -y install python-dev 

pip install lightstep


