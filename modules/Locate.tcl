# ---------------------------------------------------------------------------- #
# Locate module for Eggdrop with the Telegram-API module v20181119             #
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

proc openstreetmaps_getLocation {from_id chat_id msgid channel message parameter_start} {
	if {[set locationquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]] ne ""} {
		# Let the Telegram users know that we've received the bot command, and we're preparing an answer
		::libtelegram::sendChatAction $chat_id "find_location"

		if { [ catch {
			set result [exec curl --tlsv1.2 -s -X GET "https://nominatim.openstreetmap.org/search?q=$locationquery&format=json&polygon=0&addressdetails=0"]
		} ] } {
			putlog "Locate.tcl: cannot connect to api.openstreetmaps.com using search method."
			return -1
		}

		if {[set display_name [::libjson::getValue $result ".\[0\].display_name//empty"]] eq ""} {
			set result "[::msgcat::mc MSG_LOCATE_NOTFOUND]"
			libtelegram::sendMessage $chat_id "$result" "html" false $msgid ""
			putchan $channel "$result"
			return 0
		} else {
			set lat [::libjson::getValue $result ".\[0\].lat"]
			set lon [::libjson::getValue $result ".\[0\].lon"]
			libtelegram::sendVenue $chat_id $lat $lon $locationquery $display_name "" "" false $msgid ""
			putchan $channel "[strip_html [::libunicode::utf82ascii $display_name]]: https://www.openstreetmap.org/#map=20/$lat/$lon"
		}
		return 0
	} else {
		return -1
	}
}

::telegram::addPublicTgCommand locate openstreetmaps_getLocation "[::msgcat::mc MSG_LOCATE_HELP]"
