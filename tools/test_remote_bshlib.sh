#!/usr/bin/env bash

function test_rcml {
    local out=""
    local cmd=""
    cmd="scp -rp leo@localhost:~/file /tmp/file.bak"
    out=$(rcml $cmd)
    echo "result: $?"
    echo "result: $out"

    cmd="scp -rp leo@localhost:~/no_file /tmp/file.bak"
    out=$(rcml $cmd)
    echo "result: $?"
    echo "result: $out"
}

function test_rcml_expl {
    local out=""
    local cmd=""

    out=$(rcml_expl leo changeme localhost )

    cmd="egrep '^line1$|line2 2' /home/leo/file"
    out=$(rcml_expl leo changeme localhost $cmd)
    echo "result: $?"
    echo "result: $out"

    cmd="find /usr/include -name error.h | xargs ls -l"
    out=$(rcml_expl leo changeme localhost $cmd)
    echo "result: $?"
    echo "result: $out"
    out=$(rcml_expl leoa changeme localhost 'find /usr/include -name error.h | xargs ls -l')
    echo "result: $?"
    echo "result: $out"
    out=$(rcml_expl leo changeme1 localhost find /usr/include -name error.h \| xargs ls -l)
    echo "result: $?"
    echo "result: $out"
}

function test_rcml_host {
    local out=""
    local cmd=""

    out=$(rcml_host localhost)
    echo "result: $?"
    echo "result: $out"

    cmd="egrep '^line1$|line2 2' /home/leo/file"
    out=$(rcml_host localhost $cmd)
    echo "result: $?"
    echo "result: $out"

    cmd="find /usr/include -name error.h | xargs ls -l"
    out=$(rcml_host localhost $cmd)
    echo "result: $?"
    echo "result: $out"

    MOON_BSHAUTO_EXP_USER_PASSWD="abc"
    out=$(rcml_host localhost 'find /usr/include -name error.h | xargs ls -l')
    echo "result: $?"
    echo "result: $out"
    
    MOON_BSHAUTO_EXP_USER="abc"
    out=$(rcml_host localhost "find /usr/include -name error.h | xargs ls -l")
    echo "result: $?"
    echo "result: $out"
}

test_rcml
test_rcml_expl
test_rcml_host
