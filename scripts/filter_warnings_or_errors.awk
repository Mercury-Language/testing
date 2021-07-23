#!/usr/bin/awk -f
#
# Pick out messages of interest from build logs.
#

/^FAILED TEST/ {
    err = 1
    in_failed_test = 1
    print
    next
}

/^END OF THE LOG OF THE FAILED TEST/ {
    in_failed_test = 0
    next
}

/not successful|^ERROR/ {
    err = 1
    print
    next
}

/warning:|error:|^\*\* error/ &&
    !/make.*: undefined variable/ &&
    !/mmake.* recipe for target/ &&
    !/-j1 forced in submake: resetting jobserver mode/ &&
    !/^mercury_context\.c:.*__fdelt_warn/ &&
    !/^cp: warning: source file .* specified more than once/ &&
    !/Signal.* is internal proprietary API/ \
{
    err = 1
    if (!in_failed_test) {
        print
    }
}

END {
    exit err
}
