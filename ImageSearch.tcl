# ---------------------------------------------------------------------------- #
# Image Search module v0.1 for Eggdrop with the Telegram-API module            #
#                                                                              #
# written by Eelco Huininga 2016                                               #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #
# Image Search procedures                                                      #
# ---------------------------------------------------------------------------- #
# Search an image on DuckDuckGo                                                #
# ---------------------------------------------------------------------------- #

proc imagesearch_getImage {chat_id msgid channel message parameter_start} {
	tg_sendChatAction $chat_id "upload_photo"

	set imagequery [string range $message $parameter_start end]
	set imgresult [exec curl --tlsv1.2 -s -X GET https://duckduckgo.com/i.js?kah=nl-nl&kl=nl-nl&kad=nl_NL&kp=-1&q=$imagequery]
	# Bug: the object should really be "message" and not ""
	set url [jsonGetValue $imgresult "" "image"]
	set title [jsonGetValue $imgresult "" "title"]

	tg_sendPhoto $chat_id "$msgid" "$url" "$title"
	putchan $channel "[strip_html $url]"
}
