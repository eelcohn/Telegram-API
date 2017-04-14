# ---------------------------------------------------------------------------- #
# Soundcloud module v0.1 for Eggdrop with the Telegram-API module              #
#                                                                              #
# written by Eelco Huininga 2016                                               #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #
# Soundcloud procedures                                                        #
# ---------------------------------------------------------------------------- #
# Search a track on Soundcloud                                                 #
# ---------------------------------------------------------------------------- #

proc soundcloud_getTrack {chat_id msgid channel message parameter_start} {
	tg_sendChatAction $chat_id "typing"

	set query [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	set result [exec curl --tlsv1.2 -s -X GET https://api.soundcloud.com/tracks.json?client_id=4346c8125f4f5c40ad666bacd8e96498&q=$query&limit=1]

	set url [jsonGetValue $result "" "permalink_url"]

	tg_sendReplyToMessage $chat_id $msgid "html" "$url"
	putchan $channel "[strip_html $url]"
}
