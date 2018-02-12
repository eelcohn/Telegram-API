# ---------------------------------------------------------------------------- #
# Spotify module for Eggdrop with the Telegram-API module v20180212            #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

source "[file join [file dirname [info script]] Spotify.conf]"

# ---------------------------------------------------------------------------- #
# Spotify procedures                                                           #
# ---------------------------------------------------------------------------- #
# Search a track on Spotify                                                    #
# ---------------------------------------------------------------------------- #

proc spotify_getTrack {from_id chat_id msgid channel message parameter_start} {
	if {[set spotifyquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]] ne ""} {
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
				set url "[::msgcat::mc MSG_SPOTIFY_NOTFOUND]"
			} else {
				set url [::libjson::getValue $result "spotify"]
			}
		}

		::libtelegram::sendMessage $chat_id $msgid "html" "$url"
		putchan $channel "[strip_html $url]"

		return 0
	} else {
		return -1
	}
}

::telegram::addPublicCommand spotify spotify_getTrack "[::msgcat::mc MSG_SPOTIFY_HELP]"
