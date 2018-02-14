# ---------------------------------------------------------------------------- #
# HTTP web request library for Tcl - v20180214                                 #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #


namespace eval libhttp {
	variable processor	""
	variable errormessage	""
	variable errornumber	0
}

# ---------------------------------------------------------------------------- #
# Make a HTTP GET request and return the response                              #
# ---------------------------------------------------------------------------- #
proc ::libhttp::get {url {parameters ""}} {
	variable urldata ""
 
	switch $::libjson::processor {
		"http_pkg" {
			if {![catch {package present http}] || ![catch {package present tls}]} {
				set errormessage "::libhttp::get: Tcllib::http processor not supported"
				set errornumber -1
				return -1
			}

			foreach data value [list $parameters] {
				append urldata "$data=$value&"
			}

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set token [::http::geturl "$url?$urldata"]
			set status [::http::status $token]
			set result [::http::data $token]
			::http::cleanup $token
			::http::unregister https
		}

		"curl" {
			foreach data value [list $parameters] {
				append urldata " -d $data=$value"
			}

			if { [ catch {
				set result [exec curl --tlsv1.2 -s -X GET $url $urldata]
			} ] } {
				set errormessage "::libhttp::get: cannot connect to $url"
				set errornumber -2
				return -1
			}
		}

		default {
			set errormessage "::libhttp::get unknown http processor $::libhttp::processor"
			set errornumber -3
			return -1
		}
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# Make a HTTP POST request and return the response                             #
# ---------------------------------------------------------------------------- #
proc ::libhttp::post {url parameters} {
	variable urldata ""

	switch $::libjson::processor {
		"http_pkg" {
			if {![catch {package present http}] || ![catch {package present tls}]} {
				set errormessage "::libhttp::post: Tcllib::http processor not supported"
				set errornumber -1
				return -1
			}

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set token [::http::geturl $url -query [::http::formatQuery [list $parameters]]]
			set status [::http::status $token]
			set result [::http::data $token]
			::http::cleanup $token
			::http::unregister https
		}

		"curl" {
			foreach data value [list $parameters] {
				append urldata " -d $data=$value"
			}

			if { [ catch {
				set result [exec curl --tlsv1.2 -s -X POST $url $urldata]
			} ] } {
				set errormessage "::libhttp::post: cannot connect to $url"
				set errornumber -2
				return -1
			}
		}

		default {
			set errormessage "::libhttp::post unknown http processor $::libhttp::processor"
			set errornumber -3
			return -1
		}
	}
	return $result
}

if {$::libhttp::processor eq ""} {
	if {[catch {package present http}] && [catch {package present tls}]} {
		package require http
		package require tls
		set ::libhttp::processor "http_pkg"
	} else {
		set ::libhttp::processor "curl"
	}
}
