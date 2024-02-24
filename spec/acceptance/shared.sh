# shared shell code for all test scripts

fail()
{
	echo >&2 "FATAL - $@"
	exit 1
}

assert()
{
	eval "$@"
	if [ $? -ne 0 ] ; then
		fail "ASSERTION: $@"
	fi
}
