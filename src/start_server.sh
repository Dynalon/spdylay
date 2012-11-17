#!/bin/bash
# the trailing / in htdocs is important!

./spdyd -v -d ../htdocs/ 8080 server.key server.pem
