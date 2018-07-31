# ---------------------------------------------------------------------------- #
# Image Search module for Eggdrop with the Telegram-API module v20180731       #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

namespace eval ImageSearch {}
source "[file join [file dirname [info script]] ImageSearch.conf]"

# ---------------------------------------------------------------------------- #
# Image Search procedures                                                      #
# ---------------------------------------------------------------------------- #
# Search an image on Qwant                                                     #
# ---------------------------------------------------------------------------- #

proc imagesearch_getImage {from_id chat_id msgid channel message parameter_start} {
	if {[set imagequery [string range $message $parameter_start end]] ne ""} {
		if { [ catch {
#			set imgresult [exec curl --tlsv1.2 -s -X POST https://api.duckduckgo.com/ -d kah=nl-nl -d kl=$s_region -d kad=$s_language -d kp=$s_safesearch -d q=$imagequery]
#			set imgresult [exec curl --tlsv1.2 -s -X GET https://api.duckduckgo.com/?kah=nl-nl&kl=$s_region&kad=$s_language&kp=$s_safesearch&q=$imagequery]
			set imgresult [exec curl --tlsv1.2 -s --header "User-Agent: Mozilla/5.0" -X GET https://api.qwant.com/api/search/ia -d t=images -d count=1 -d offset=1 -d safesearch=$::ImageSearch::safesearch -d locale=$::ImageSearch::locale -d q=$imagequery -d t=all]
		} ] } {
			putlog "Telegram-API: cannot connect to api.qwant.com using imagesearch_getImage method."
			set imgresult ""
		}

		set status [::libjson::getValue $imgresult ".status//empty"]

		if {$status != "success"} {
			set error_code [::libjson::getValue $imgresult ".data.error_code//empty"]
			set reply [::msgcat::mc MSG_IMAGESEARCH_ERROR "$status" "$error_code"]
			::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid "" 
			putchan $channel "$reply"
		} else {
			set media [::libjson::getValue $imgresult ".data.result.items\[0\].data\[0\].media_fullsize//empty"]
			if {$media == ""} {
				set reply [::msgcat::mc MSG_IMAGESEARCH_NOTFOUND]
				::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid "" 
				putchan $channel "$reply"
			} else {
				set title [::libjson::getValue $imgresult ".data.result.items\[0\].data\[0\].title//empty"]
				set url [::libjson::getValue $imgresult ".data.result.items\[0\].data\[0\].url//empty"]
				::libtelegram::sendPhoto $chat_id "https:$media" "<a href=\"$url\">$title</a>" "html" false $msgid ""
				putchan $channel "https:$media"
			}
		}

		# Return success
		return 0
	} else {
		# Return an error, so the help message will be shown
		return -1
	}
}

::telegram::addPublicCommand get imagesearch_getImage "[::msgcat::mc MSG_IMAGESEARCH_HELP]"
