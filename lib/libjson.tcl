# ---------------------------------------------------------------------------- #
# Telegram-API module v20171216 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #


namespace eval libjson {
	variable processor

# ---------------------------------------------------------------------------- #
# Check if a JSON key is present                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::hasKey {record key} {
	if {[string first $key $record] != -1} {
		return 1
	} else {
		return 0
	}
}

# ---------------------------------------------------------------------------- #
# Return the value of a JSON key                                               #
# ---------------------------------------------------------------------------- #
proc ::libjson::getValue {record object key} {
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

