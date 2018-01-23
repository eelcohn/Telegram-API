# ---------------------------------------------------------------------------- #
# HTTP web request module v20180123 for Eggdrop                                #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #


namespace eval libhttp {
	variable processor
	variable errormessage
	variable errornumber
}

# ---------------------------------------------------------------------------- #
# Make a HTTP request and return the response                                  #
# ---------------------------------------------------------------------------- #
proc ::libhttp::request {url type parameters} {
	switch $::libjson::processor {
		"http_pkg" {
			set errormessage "Tcllib::http processor not supported"
			set errornumber -1
			return -1

			::http::register https 443 [list ::tls::socket -tls1 1 -ssl2 0 -ssl3 0]
			if {$type eq "POST"} {
				set request [::http::geturl $url -query [::http::formatQuery [list $parameters]]]
			} else {
				set request [::http::geturl $url]
			}
			http::cleanup $request
		}

		"curl" {
			set curldata ""
 
			foreach data value [list $parameters] {
				lappend " -d $data=$value" $curldata
			}

			if { [ catch {
				set result [exec curl --tlsv1.2 -s -X $type $url $curldata]
			} ] } {
				set errormessage "::libhttp::request: cannot connect to $url"
				set errornumber -2
				return -1
			}
		}

		default {
			set errormessage "::libhttp::request unknown http processor $::libhttp::processor"
			set errornumber -3
			return -1
		}
	}
}

if {[catch {package present http}] && [catch {package present tls}]} {
	package require http
	package require tls
	set ::libhttp::processor "http_pkg"
} else {
	set ::libhttp::processor "curl"
}
