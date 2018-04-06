#!/bin/sh

# Builds with gcc.  Could work with others, but IDK if they provide the
# profiler and debugging info.

name=$(basename "$PWD")

CFLAGS="-Wall -Wextra -Werror $CFLAGS"

if [ -f qc.env ]; then
    . $PWD/qc.env
fi

src_file='main.c'

cmd="$1"
if [ -z "$cmd" ]; then
    cmd='run'
fi

log() {
    [ -z "$LOG" ] || echo "LOG: $1" >&2
}

build() {
    extra_flags="$1"
    log "extra_flags: $extra_flags"

    log 'build'
    time -f 'compile: %e seconds' gcc $CFLAGS $extra_flags -o "$name" "$src_file" $lib_flags
}

debug() {
    log 'debug'
    build '-Og -g' && gdb "$name"
}

profile() {
    log 'profile'
    build '-fprofile-arcs -pg' && "./$name" $run_args
    gprof --brief "$name" gmon.out > "$name.profile"
}

run() {
    local prog_name="$1"
    if [ -z "$prog_name" ]; then
        prog_name="./$name"
    fi

    log 'run'
    build '-Og' && "$prog_name" $run_args
}

clean() {
    log 'clean'
    [ ! -e "$name" ] || rm "$name"
    rm -f gmon.out "$name.profile" main.gcda

    exit 0
}

if [ "$cmd" = 'build' ]; then
    build
elif [ "$cmd" = 'clean' ]; then
    clean
elif [ "$cmd" = 'debug' ]; then
    debug
elif [ "$cmd" = 'profile' ]; then
    profile
elif [ "$cmd" = 'run' ]; then
    run
else
    # build to /tmp
    name=$(mktemp)
    src_file="$cmd"
    run "$name"
    rm "$name"
fi

