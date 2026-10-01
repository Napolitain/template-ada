#!/bin/sh
# Coverage with GNATcoverage (source instrumentation); fails below COVERAGE_MIN % lines (default 80).
# Report on stdout, annotated sources (*.xcov) in tests/obj/coverage/, Cobertura XML in tests/obj/cobertura/.
# The main (template.adb) is excluded: keep it thin.
set -eu
cd "$(dirname "$0")"
min="${COVERAGE_MIN:-80}"

# Generate config/*.gpr for both crates (missing on a fresh clone).
(cd .. && alr -n -q build --stop-after=generation)
alr -n -q build --stop-after=generation

rts="$PWD/obj/gnatcov-rts"
level="stmt+decision"
[ -d "$rts" ] || alr exec -- gnatcov setup --prefix="$rts"
export GPR_PROJECT_PATH="$rts/share/gpr${GPR_PROJECT_PATH:+:$GPR_PROJECT_PATH}"

alr exec -- gnatcov instrument -P template_tests.gpr --projects=template --level="$level"
alr exec -- gprbuild -q -P template_tests.gpr --src-subdirs=gnatcov-instr --implicit-with=gnatcov_rts

rm -rf obj/traces obj/coverage obj/cobertura && mkdir -p obj/traces
GNATCOV_TRACE_FILE=obj/traces/ ./bin/tests_main

cov() {
    alr exec -- gnatcov coverage -P template_tests.gpr --projects=template --level="$level" \
        --excluded-source-files=template.adb "$@" obj/traces/*.srctrace
}
cov --annotate=report
cov --annotate=xcov+ --output-dir=obj/coverage
cov --annotate=cobertura --output-dir=obj/cobertura

# Overall line rate from the Cobertura root element.
tr ' ' '\n' <obj/cobertura/cobertura.xml | awk -F'"' -v min="$min" '
    /^lines-covered=/ { covered = $2 }
    /^lines-valid=/ { valid = $2; exit }
    END {
        pct = valid ? 100 * covered / valid : 100
        printf "line coverage %.2f%% (%d/%d, min %s%%)\n", pct, covered, valid, min
        if (pct < min) { print "coverage below " min "%"; exit 1 }
    }'
