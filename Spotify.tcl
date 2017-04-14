# ---------------------------------------------------------------------------- #
# Spotify module v0.1 for Eggdrop with the Telegram-API module                 #
#                                                                              #
# written by Eelco Huininga 2016                                               #
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
	tg_sendChatAction $chat_id "typing"

	set spotifyquery [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	set result [exec curl --tlsv1.2 -s -X GET https://api.spotify.com/v1/search?q=$spotifyquery&type=track&limit=1]

	set result [string map {" : " ":"} $result]
	if {[jsonGetValue $result "" "total"] eq "0"} {
		set url "Nothing found."
	} else {
		set url [jsonGetValue $result "" "spotify"]
	}

	tg_sendReplyToMessage $chat_id $msgid "html" "$url"
	putchan $channel "[strip_html $url]"
}
