#!/bin/bash
# the trailing / in htdocs is important!

./spdyd -3 -v -d ../htdocs/ 8080 server.key server.pem $@
