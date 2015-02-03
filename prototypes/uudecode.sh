#!/bin/sh

# uudecode in POSIX bourne shell
#
# *EXCRUCIATINGLY* SLOW!!!
#
# Taken from a reply to a blog post here:
# http://www.weeklywhinge.com/?p=108
#
# Copyright (c) 2015, Rafael Kitover <rkitover@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

bs=0
while read -rs t ; do
        if [ "$bs" -eq 1 ] ; then
                if [ "a$t" = "aend" ] ; then
                        bs=2
                else
                        set $(printf "%d " "'${t:0:1}" "'${t:1:1}" "'${t:2:1}" "'${t:3:1}" "'${t:4:1}" "'${t:5:1}" "'${t:6:1}" "'${t:7:1}" "'${t:8:1}" "'${t:9:1}" "'${t:10:1}" "'${t:11:1}" "'${t:12:1}" "'${t:13:1}" "'${t:14:1}" "'${t:15:1}" "'${t:16:1}" "'${t:17:1}" "'${t:18:1}" "'${t:19:1}" "'${t:20:1}" "'${t:21:1}" "'${t:22:1}" "'${t:23:1}" "'${t:24:1}" "'${t:25:1}" "'${t:26:1}" "'${t:27:1}" "'${t:28:1}" "'${t:29:1}" "'${t:30:1}" "'${t:31:1}" "'${t:32:1}" "'${t:33:1}" "'${t:34:1}" "'${t:35:1}" "'${t:36:1}" "'${t:37:1}" "'${t:38:1}" "'${t:39:1}" "'${t:40:1}" "'${t:41:1}" "'${t:42:1}" "'${t:43:1}" "'${t:44:1}" "'${t:45:1}" "'${t:46:1}" "'${t:47:1}" "'${t:48:1}" "'${t:49:1}" "'${t:50:1}" "'${t:51:1}" "'${t:52:1}" "'${t:53:1}" "'${t:54:1}" "'${t:55:1}" "'${t:56:1}" "'${t:57:1}" "'${t:58:1}" "'${t:59:1}" "'${t:60:1}")
                        l=$(($1 -32 & 63 ))
                        shift
                        while [ $l -gt 0 ] ; do
                                i0=$(($1 -32 & 63))
                                shift
                                i1=$(($1 -32 & 63))
                                shift
                                i2=$(($1 -32 & 63))
                                shift
                                i3=$(($1 -32 & 63))
                                shift
                                if [ $l -gt 2 ] ; then
                                        echo -ne "\0$(($i0 >> 4))$(($i0 >> 1 & 7))$(($i0 << 2 & 4 | $i1 >> 4))\0$(($i1 >> 2 & 3))$(($i1 << 1 & 6 | $i2 >> 5))$(($i2 >> 2 & 7))\0$(($i2 & 3))$(($i3 >> 3 & 7))$(($i3 & 7))"
                                        true
                                elif [ $l -eq 2 ] ; then
                                        echo -ne "\0$(($i0 >> 4))$(($i0 >> 1 & 7))$(($i0 << 2 & 4 | $i1 >> 4))\0$(($i1 >> 2 & 3))$(($i1 << 1 & 6 | $i2 >> 5))$(($i2 >> 2 & 7))"
                                        true
                                else
                                        echo -ne "\0$(($i0 >> 4))$(($i0 >> 1 & 7))$(($i0 << 2 & 4 | $i1 >> 4))"
                                        true
                                fi
                                l=$(($l-3))
                        done
                fi
        elif [ "${t:0:5}" = "begin" ]; then
                bs=1
        fi
done
