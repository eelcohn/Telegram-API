# ---------------------------------------------------------------------------- #
# Locate module v0.1 for Eggdrop with the Telegram-API module v20171216        #
#                                                                              #
# written by Eelco Huininga 2017                                               #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #
# OpenStreetMaps procedures                                                    #
# ---------------------------------------------------------------------------- #
# Search a location on OpenStreetMaps                                          #
# ---------------------------------------------------------------------------- #

proc openstreetmaps_getLocation {chat_id msgid channel message parameter_start} {
	set locationquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X GET "https://nominatim.openstreetmap.org/search?q=$locationquery&format=json&polygon=0&addressdetails=0"]
	} ] } {
		putlog "Locate.tcl: cannot connect to api.openstreetmaps.com using search method: $result"
		return -1
	}

	set result [string map {" : " ":"} $result]
	set display_name [jsonGetValue $result "" "display_name"]
	if {$display_name eq ""} {
		libtelegram::sendReplyToMessage $chat_id $msgid "html" "Nothing found."
		putchan $channel "Nothing found."
	} else {
		set lat [jsonGetValue $result "" "lat"]
		set lon [jsonGetValue $result "" "lon"]
		libtelegram::sendVenue $chat_id $msgid $lat $lon $locationquery $display_name
		putchan $channel "[strip_html $display_name] is at $lat $lon"
	}
}
