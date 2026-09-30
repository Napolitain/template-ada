#!/bin/sh
# Coverage with GNATcoverage (source instrumentation).
# Report on stdout, annotated sources (*.xcov) in tests/obj/coverage/.
set -eu
cd "$(dirname "$0")"

rts="$PWD/obj/gnatcov-rts"
level="stmt+decision"
[ -d "$rts" ] || alr exec -- gnatcov setup --prefix="$rts"
export GPR_PROJECT_PATH="$rts/share/gpr${GPR_PROJECT_PATH:+:$GPR_PROJECT_PATH}"

alr exec -- gnatcov instrument -P template_tests.gpr --projects=template --level="$level"
alr exec -- gprbuild -q -P template_tests.gpr --src-subdirs=gnatcov-instr --implicit-with=gnatcov_rts

rm -rf obj/traces obj/coverage && mkdir -p obj/traces
GNATCOV_TRACE_FILE=obj/traces/ ./bin/tests_main

set -- obj/traces/*.srctrace
alr exec -- gnatcov coverage -P template_tests.gpr --projects=template --level="$level" --annotate=report "$@"
alr exec -- gnatcov coverage -P template_tests.gpr --projects=template --level="$level" --annotate=xcov+ --output-dir=obj/coverage "$@"
