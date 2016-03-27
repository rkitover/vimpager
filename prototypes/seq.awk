#!/bin/sh

echo | awk '
    {
        start = arg1
        stop  = arg2
        step  = 1

        if (num_args == 3) {
            step = arg2
            stop = arg3
        }

        for (i = start; i != stop + step; i += step)
            print i

        exit(0)
    }
' num_args="$#" arg1="$1" arg2="$2" arg3="$3"
