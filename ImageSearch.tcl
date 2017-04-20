# ---------------------------------------------------------------------------- #
# Image Search module v0.1 for Eggdrop with the Telegram-API module            #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

# Safe Search: -2 for 'Off', -1 for 'Average', 0 for 'On'

# ---------------------------------------------------------------------------- #
# Image Search procedures                                                      #
# ---------------------------------------------------------------------------- #
# Search an image on DuckDuckGo                                                #
# ---------------------------------------------------------------------------- #

proc imagesearch_getImage {chat_id msgid channel message parameter_start} {
	set s_region nl_nl
	set s_language nl_NL
	set s_safesearch -2

	tg_sendChatAction $chat_id "upload_photo"

	set imagequery [string range $message $parameter_start end]
	if { [ catch {
		set imgresult [exec curl --tlsv1.2 -s -X GET https://api.duckduckgo.com/?kah=nl-nl&kl=$s_region&kad=$s_language&kp=$s_safesearch&q=$imagequery]
	} ] } {
		putlog "Telegram-API: cannot connect to api.duckduckgo.com using imagesearch_getImage method: $imgresult"
	}

	# Bug: the object should really be "message" and not ""
	set url [jsonGetValue $imgresult "" "Image"]
	set title [jsonGetValue $imgresult "" "Abstract"]

	if {$url == ""} {
		tg_sendMessage $chat_id "html" "Nothing found :-("
		putchan $channel "Nothing found :-("
	} else {
		tg_sendPhoto $chat_id "$msgid" "$url" "$title"
		putchan $channel "[strip_html $url]"
	}
}
