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
			set imgresult [exec curl --tlsv1.2 -s --header "User-Agent: Mozilla/5.0" -X GET https://api.qwant.com/api/search/images -d count=1 -d offset=1 -d safesearch=$::ImageSearch::safesearch -d locale=$::ImageSearch::locale -d q=$imagequery]
		} ] } {
			putlog "Telegram-API: cannot connect to api.qwant.com using imagesearch_getImage method."
			set imgresult ""
		}

		set status [::libjson::getValue $imgresult ".status//empty"]
		set error_code [::libjson::getValue $imgresult ".data.error_code//empty"]
		set url [::libjson::getValue $imgresult ".data.result.items\[0\].media//empty"]
		set title [::libjson::getValue $imgresult ".data.result.items\[0\].url//empty"]

		if {($status != "success") || ($error_code != 0)} {
			set reply [::msgcat::mc MSG_IMAGESEARCH_ERROR "status=$status error_code=$error_code"]
			::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid "" 
			putchan $channel "$reply"
		} else {
			if {$url == ""} {
				set reply [::msgcat::mc MSG_IMAGESEARCH_NOTFOUND]
				::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid "" 
				putchan $channel "$reply"
			} else {
				::libtelegram::sendPhoto $chat_id "$url" "$title" "html" false $msgid ""
				putchan $channel "[strip_html $url]"
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
