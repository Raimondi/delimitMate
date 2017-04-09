package require tcltest 2
namespace import -force ::tcltest::*
configure {*}$argv -testdir [file dir [info script]]

# Hook to determine if any of the tests failed. Then we can exit with
# proper exit code: 0=all passed, 1=one or more failed
proc tcltest::cleanupTestsHook {} {
	variable numTests
	upvar 2 testFileFailures crashed
	set ::exitCode [expr {$numTests(Failed) > 0}]
	if {[info exists crashed]} {
		set ::exitCode [expr {$::exitCode || [llength $crashed]}]
	}
}

runAllTests
puts "\a"
exit $exitCode
