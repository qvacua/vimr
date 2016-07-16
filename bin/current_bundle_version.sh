#!/bin/bash

agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/'

