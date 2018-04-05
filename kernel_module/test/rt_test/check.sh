#!/bin/bash

taskset -c 0 chrt -f 5 ./task CRIT 2 3 1&
taskset -c 0 chrt -f 10 ./task INTR 3 2 0&
