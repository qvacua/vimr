#!/bin/bash

agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/'

