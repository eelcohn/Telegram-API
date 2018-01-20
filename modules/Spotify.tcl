# ---------------------------------------------------------------------------- #
# Spotify module for Eggdrop with the Telegram-API module v20180119            #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
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
		putlog "Spotify.tcl: cannot connect to api.spotify.com using search method."
		return -1
	}

	if {[::libjson::hasKey $result ".error"]} {
		set url "Error [::libjson::getValue $result ".error.status"] [::libjson::getValue $result ".error.message"]"
	} else {
		if {[::libjson::getValue $result "total"] eq "0"} {
			set url "Nothing found."
		} else {
			set url [::libjson::getValue $result "spotify"]
		}
	}

	::libtelegram::sendMessage $chat_id $msgid "html" "$url"
	putchan $channel "[strip_html $url]"
}

add_public_command spotify spotify_getTrack

