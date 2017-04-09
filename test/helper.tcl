if {[lsearch [namespace children] ::tcltest] == -1} {
  package require tcltest 2
  namespace import -force ::tcltest::*
}

configure -verbose {body error skip}
#configure -verbose {start msec pass body error skip}

set charMap [list    \
    "\""      "\\\"" \
    "\$"      "\\$"  \
    "\["      "\\\[" \
    "\]"      "\\\]" \
    "\\"      "\\\\" \
    "{"       "\\{"  \
    "}"       "\\}"  \
  ]

# In order to skip a test pass a script that, when evaluated, returns emptyTest
# for tests that can not pass, or knownBug for ToDo features. e.g.:
#   {expr "[string first {i'} \"${input}\"] > -1 ? {emptyTest} : {}"}
# see tcltest documentation for other values.

proc single {name desc setup input result \
  {vimCmds {}}                            \
  {constr {}}                             \
  } {
  set fnamePrefix "test_${name}"
  global charMap
  makeFile ${setup} "${fnamePrefix}.in"
  makeFile {} "${fnamePrefix}.out"
  makeFile [join ${vimCmds} "\n"] "${fnamePrefix}.vim"
  set input [string map ${charMap} ${input}]
  #puts [lindex ${vimCmds} 0]
  set optCharMap [list {[} {\[} {]} {\]}]
  set vimArgs [lmap option ${vimCmds} \
      {string cat " -c \"[string map $charMap ${option}]\""}]
  set body [string cat "
  exec -- ./test.exp \"${fnamePrefix}\" \"${input}\"
  return \[viewFile \"${fnamePrefix}.out\"\]
  " ]
  #puts ${body}
  if {[string length ${desc}] eq 0} {
    set desc ${input}
  }
  if {[string length ${constr}] ne 0} {
    #puts ${constr}
    set constr [eval ${constr}]
    #puts ${constr}
  }
  set name "${name}:  \"${setup}\", \"${desc}\" ->"
  #puts $desc
  #puts $name
  test ${name}               \
      ${desc}                \
      -body ${body}          \
      -constraints ${constr} \
      -result ${result}
}

proc multi {items evalScript name desc setup input result \
  {vimCmds {}}                                            \
  {constr {}}                                             \
  } {
  global charMap
  set minor 0
  foreach item $items {
    incr minor
    eval ${evalScript}
    foreach var {desc setup input result} {
      set "the_${var}"   [string map ${aCharMap} [expr "$${var}"]]
    }
    set the_name "${name}.${minor}"
    single       \
        ${the_name}   \
        ${the_desc}   \
        ${the_setup}  \
        ${the_input}  \
        ${the_result} \
        ${vimCmds}    \
        ${constr}     \
  }
}

proc quotes {name desc setup input result \
  {vimCmds {}}                            \
  {constr {}}                             \
  } {
  set quotes [list {'} \" {`} {«} {|}]
  set mapScript {set aCharMap [list "'" ${item}]}
  multi       \
      ${quotes}    \
      ${mapScript} \
      ${name}      \
      ${desc}      \
      ${setup}     \
      ${input}     \
      ${result}    \
      ${vimCmds}   \
      ${constr}    \
}

proc pairs {name desc setup input result \
  {vimCmds {}}                           \
  {constr {}}                            \
  } {
  set pairs [list () \{\} \[\] <> ¿? ¡!  ,:]
  set mapScript {
    set left [string index ${item} 0]
    set right [string index ${item} 1]
    set aCharMap [list ( ${left} ) ${right}]
  }
  multi       \
      ${pairs}     \
      ${mapScript} \
      ${name}      \
      ${desc}      \
      ${setup}     \
      ${input}     \
      ${result}    \
      ${vimCmds}   \
      ${constr}    \
}

# vim: set filetype=tcl et sw=2 sts=0 ts=8:
