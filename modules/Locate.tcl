# ---------------------------------------------------------------------------- #
# Locate module for Eggdrop with the Telegram-API module v20180211             #
#                                                                              #
# written by Eelco Huininga 2017-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

source "[file join [file dirname [info script]] Locate.conf]"

# ---------------------------------------------------------------------------- #
# OpenStreetMaps procedures                                                    #
# ---------------------------------------------------------------------------- #
# Search a location on OpenStreetMaps                                          #
# ---------------------------------------------------------------------------- #

proc openstreetmaps_getLocation {chat_id msgid channel message parameter_start} {
	if {[set locationquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]] ne ""} {
		if { [ catch {
			set result [exec curl --tlsv1.2 -s -X GET "https://nominatim.openstreetmap.org/search?q=$locationquery&format=json&polygon=0&addressdetails=0"]
		} ] } {
			putlog "Locate.tcl: cannot connect to api.openstreetmaps.com using search method."
			return -1
		}

		set result [string map {" : " ":"} $result]
		set display_name [::libjson::getValue $result ".\[0\].display_name//empty"]
		if {$display_name eq ""} {
			set result "[::msgcat::mc MSG_LOCATE_NOTFOUND]"
			libtelegram::sendReplyToMessage $chat_id $msgid "html" "$result"
			putchan $channel "$result"
		} else {
			set lat [::libjson::getValue $result ".\[0\].lat"]
			set lon [::libjson::getValue $result ".\[0\].lon"]
			libtelegram::sendVenue $chat_id $msgid $lat $lon $locationquery $display_name
			putchan $channel "[strip_html $display_name]: https://www.openstreetmap.org/#map=20/$lat/$lon"
		}
		return 0
	} else {
		return -1
	}
}

::telegram::addPublicCommand locate openstreetmaps_getLocation "[::msgcat::mc MSG_LOCATE_HELP]"
