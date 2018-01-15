# ---------------------------------------------------------------------------- #
# Telegram-API module v20180115 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #


namespace eval libjson {
	variable processor

# ---------------------------------------------------------------------------- #
# Check if a JSON key is present                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::hasKey {record key} {
	switch $::libjson::processor {
		"json_pkg" {
			putlog "Tcllib::json json processor not supported"
		}

		"jq" {
			putlog "jq json processor not supported"
		}

		"internal" {
			return [::libjson::internal::hasKey $record $key]
		}

		default {
			putlog "::libjson::hasKey unknown json processor $::libjson::processor"
		}
	}
}

# ---------------------------------------------------------------------------- #
# Return the value of a JSON key                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::getValue {record object key} {
	switch $::libjson::processor {
		"json_pkg" {
			putlog "Tcllib::json json processor not supported"
		}

		"jq" {
			putlog "jq json processor not supported"
		}

		"internal" {
			return [::libjson::internal::getValue $record $object $key]
		}

		default {
			putlog "::libjson::hasKey unknown json processor $::libjson::processor"
		}
	}
}

}

namespace eval ::libjson::internal {

# ---------------------------------------------------------------------------- #
# Check if a JSON key is present                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::internal::hasKey {record key} {
	if {[string first [string range $key [string last "." $key]+1 end] $record] != -1} {
		return 1
	} else {
		return 0
	}
}

# ---------------------------------------------------------------------------- #
# Return the value of a JSON key                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::internal::getValue {record object key} {
	set length [string length $key]
	set objectstart [string first "\"$object\":\{" $record]
	# Bug: this is a quick fix because this procedure doesn't iterate through all the objects correctly yet
	if {$object eq ""} {
		set objectend [string length $record]
	} else {
		set objectend [string first "\}" $record $objectstart]
	}

	set keystart [string first "\"$key\":" $record $objectstart]
	if {$keystart != -1} {
		if {$keystart < $objectend} {
			if {[string index $record [expr $keystart+$length+3]] eq "\""} {
				set end [string first "\"" $record [expr $keystart+$length+5]]
				return [string range $record [expr $keystart+$length+4] $end-1]
			} else {
				set end [string first "," $record [expr $keystart+$length+3]]
				if {$end != -1} {
					return [string range $record [expr $keystart+$length+3] $end-1]
				} else {
					set end [string first "\}" $record [expr $keystart+$length+3]]
					if {$end != -1} {
						return [string trim [string range $record [expr $keystart+$length+3] $end-1]]
					} else {
						return "UNKNOWN"
					}
				}
			}
		}
	}
	return ""
}

}

# http://wiki.tcl.tk/11630

# jq-0.4.0.tm
# To use this module you need jq version 1.5rc1 or later installed.
namespace eval ::libjson::jq {
	proc jq {filter data {options {-r}}} {
		exec jq {*}$options $filter << $data
	}
	proc json2dict {data} {
		jq {
			def totcl:
				if type == "array" then
					# Convert array to object with keys 0, 1, 2... and process
					# it as object.
					[range(0;length) as $i
						| {key: $i | tostring, value: .[$i]}]
					| from_entries
					| totcl
				elif type == "object" then
					.
					| to_entries
					| map("{\(.key)} {\(.value | totcl)}")
					| join(" ")
				else
					tostring
					| gsub("{"; "\\{")
					| gsub("}"; "\\}")
				end;
			. | totcl
		} $data
	}
}


# Default JSON processor is Tcl's json package
set ::libjson::processor "json_pkg"

# Fall back to jq if the json package isn't available
if { [ catch {
	package require json
} ] } {
	set ::libjson::processor "jq"
}

# Fall back to internal code in this library if both the json package and jq aren't available
if { [catch {
	[exec jq --help]
} ] } {
	set ::libjson::processor "internal"
}

