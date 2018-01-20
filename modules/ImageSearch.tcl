# ---------------------------------------------------------------------------- #
# Image Search module for Eggdrop with the Telegram-API module v20180115       #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
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

	set imagequery [string range $message $parameter_start end]
	if { [ catch {
#		set imgresult [exec curl --tlsv1.2 -s -X POST https://api.duckduckgo.com/ -d kah=nl-nl -d kl=$s_region -d kad=$s_language -d kp=$s_safesearch -d q=$imagequery]
#		set imgresult [exec curl --tlsv1.2 -s -X GET https://api.duckduckgo.com/?kah=nl-nl&kl=$s_region&kad=$s_language&kp=$s_safesearch&q=$imagequery]
		set imgresult [exec curl --tlsv1.2 -s --header "User-Agent: Mozilla/5.0" -X GET https://api.qwant.com/api/search/images -d count=1 -d offset=1 -d safesearch=0 -d locale=nl_NL -d q=$imagequery]
	} ] } {
		putlog "Telegram-API: cannot connect to api.qwant.com using imagesearch_getImage method."
		return -1
	}

	set url [remove_slashes [::libjson::getValue $imgresult ".data.result.items\[0\].media"]]
	set title [remove_slashes [::libjson::getValue $imgresult ".data.result.items\[0\].url"]]

	if {$url == ""} {
		::libtelegram::sendMessage $chat_id "$msgid" "html" "Nothing found :-("
		putchan $channel "Nothing found :-("
	} else {
		::libtelegram::sendPhoto $chat_id "$msgid" "$url" "$title"
		putchan $channel "[strip_html $url]"
	}
}

add_public_command get imagesearch_getImage
