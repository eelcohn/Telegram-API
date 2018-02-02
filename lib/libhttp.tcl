# ---------------------------------------------------------------------------- #
# HTTP web request library for Tcl - v20180123                                 #
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
proc ::libhttp::get {url parameters} {
	switch $::libjson::processor {
		"http_pkg" {
			set errormessage "Tcllib::http processor not supported"
			set errornumber -1
			return -1

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set request [::http::geturl $url]
			set result [::http::data $request]
			http::cleanup $request
		}

		"curl" {
			set curldata ""
 
			foreach data value [list $parameters] {
				lappend " -d $data=$value" $curldata
			}

			if { [ catch {
				set result [exec curl --tlsv1.2 -s -X GET $url $curldata]
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
# Make a HTTP POST request and return the response                              #
# ---------------------------------------------------------------------------- #
proc ::libhttp::post {url parameters} {
	switch $::libjson::processor {
		"http_pkg" {
			set errormessage "Tcllib::http processor not supported"
			set errornumber -1
			return -1

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set request [::http::geturl $url -query [::http::formatQuery [list $parameters]]]
			set result [::http::data $request]
			http::cleanup $request
		}

		"curl" {
			set curldata ""
 
			foreach data value [list $parameters] {
				lappend " -d $data=$value" $curldata
			}

			if { [ catch {
				set result [exec curl --tlsv1.2 -s -X POST $url $curldata]
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
