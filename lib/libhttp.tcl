# ---------------------------------------------------------------------------- #
# HTTP web request library for Tcl - v20180222                                 #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #


namespace eval libhttp {
	variable	::libhttp::processor	""
	variable	::libhttp::status
	variable	::libhttp::result
	variable	::libhttp::errorMessage	""
	variable	::libhttp::errorNumber	0
}

# ---------------------------------------------------------------------------- #
# Make a HTTP GET request and return the response                              #
# ---------------------------------------------------------------------------- #
proc ::libhttp::get {url {parameters ""}} {
	variable urldata ""
	set ::libhttp::errorNumber 0
 
	switch $::libjson::processor {
		"http_pkg" {
			if {![catch {package present http}] || ![catch {package present tls}]} {
				set ::libhttp::errorMessage "::libhttp::get: Tcllib::http processor not supported"
				set ::libhttp::errorNumber -1
			}

			foreach data value [list $parameters] {
				append urldata "$data=$value&"
			}

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set token [::http::geturl "$url?$urldata"]
			set ::libhttp::status [::http::status $token]
			set ::libhttp::result [::http::data $token]
			::http::cleanup $token
			::http::unregister https
		}

		"curl" {
			foreach data value [list $parameters] {
				append urldata " -d $data=$value"
			}

			if { [ catch {
				set ::libhttp::result [exec curl --tlsv1.2 -s -X GET $url $urldata]
			} ] } {
				set ::libhttp::errorMessage "::libhttp::get: cannot connect to $url"
				set ::libhttp::errorNumber -2
			}
		}

		default {
			set ::libhttp::errorMessage "::libhttp::get unknown http processor $::libhttp::processor"
			set ::libhttp::errorNumber -3
		}
	}
	return $::libhttp::errorNumber
}

# ---------------------------------------------------------------------------- #
# Make a HTTP POST request and return the response                             #
# ---------------------------------------------------------------------------- #
proc ::libhttp::post {url parameters} {
	variable urldata ""
	set ::libhttp::errorNumber 0

	switch $::libjson::processor {
		"http_pkg" {
			if {![catch {package present http}] || ![catch {package present tls}]} {
				set ::libhttp::errormessage "::libhttp::post: Tcllib::http processor not supported"
				set ::libhttp::errornumber -1
			}

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			set token [::http::geturl $url -query [::http::formatQuery [list $parameters]]]
			set ::libhttp::status [::http::status $token]
			set ::libhttp::result [::http::data $token]
			::http::cleanup $token
			::http::unregister https
		}

		"curl" {
			foreach data value [list $parameters] {
				append urldata " -d $data=$value"
			}

			if { [ catch {
				set ::libhttp::result [exec curl --tlsv1.2 -s -X POST $url $urldata]
			} ] } {
				set ::libhttp::errorMessage "::libhttp::post: cannot connect to $url"
				set ::libhttp::errorNumber -2
			}
		}

		default {
			set ::libhttp::errorMessage "::libhttp::post unknown http processor $::libhttp::processor"
			set ::libhttp::errorNumber -3
		}
	}
	return $::libhttp::errorNumber
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
