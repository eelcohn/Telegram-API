# ---------------------------------------------------------------------------- #
# Spotify module v0.1 for Eggdrop with the Telegram-API module v20171216       #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #
# Spotify procedures                                                           #
# ---------------------------------------------------------------------------- #
# Search a track on Spotify                                                    #
# ---------------------------------------------------------------------------- #

proc spotify_getTrack {chat_id msgid channel message parameter_start} {
	set spotifyquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X GET https://api.spotify.com/v1/search?q=$spotifyquery&type=track&limit=1]
	} ] } {
		putlog "Spotify.tcl: cannot connect to api.spotify.com using search method: $result"
		return -1
	}

	set result [string map {" : " ":"} $result]
	if {[jsonGetValue $result "" "total"] eq "0"} {
		set url "Nothing found."
	} else {
		set url [jsonGetValue $result "" "spotify"]
	}

	libtelegram::sendReplyToMessage $chat_id $msgid "html" "$url"
	putchan $channel "[strip_html $url]"
}
