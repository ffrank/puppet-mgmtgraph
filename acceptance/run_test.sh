#!/bin/bash

set -e

cd $( dirname $0 )

for test in test_* ; do
	test -x $test || continue
	echo "[ACCEPTANCE] Running $test ..."
	if ! ./$test ; then
		echo FAIL
		break
	fi
	echo
done
