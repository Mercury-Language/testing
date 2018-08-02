#!/usr/bin/awk -f
#
# Pick out messages of interest from build logs.
#

/warning:|error:|not successful|^\*\* error|^FAILED TEST/ &&
    !/make.*: undefined variable/ &&
    !/mmake.* recipe for target/ &&
    !/submake: disabling jobserver/ &&
    !/^mercury_context\.c:.*__fdelt_warn/ &&
    !/Signal.* is internal proprietary API/ \
{
    print
    err = 1
}

END {
    exit err
}
