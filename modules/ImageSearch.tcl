# ---------------------------------------------------------------------------- #
# Image Search module for Eggdrop with the Telegram-API module v20180810       #
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

proc ::ImageSearch::getImage {from_id chat_id msgid channel message parameter_start} {
	if {[set imagequery [string trim [string range $message $parameter_start end]]] ne ""} {
		if { [ catch {
#			set imgresult [exec curl --tlsv1.2 -s -X POST https://api.duckduckgo.com/ -d kah=nl-nl -d kl=$s_region -d kad=$s_language -d kp=$s_safesearch -d q=$imagequery]
#			set imgresult [exec curl --tlsv1.2 -s -X GET https://api.duckduckgo.com/?kah=nl-nl&kl=$s_region&kad=$s_language&kp=$s_safesearch&q=$imagequery]
			set imgresult [exec curl --tlsv1.2 -s --header "User-Agent: Mozilla/5.0" -X GET https://api.qwant.com/api/search/ia -d t=images -d count=1 -d offset=1 -d safesearch=$::ImageSearch::safesearch -d locale=$::ImageSearch::locale -d q=$imagequery -d t=all]
		} ] } {
			putlog "::ImageSearch::getImage: cannot connect to api.qwant.com."
			set imgresult ""
		}

		if {[set status [::libjson::getValue $imgresult ".status//empty"]] ne "success"} {
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
				# Quick fix to replace HTML-entities (&xxxx;) with ?
				# Should really use [string map...], tDOM or htmlparse::mapEscapes
				set title [regsub -all {&(.|\n|\r)+?;} $title "?"]
				::libtelegram::sendPhoto $chat_id "https:$media" "<a href=\"$url\">$title</a>" "html" false $msgid ""
				putchan $channel "https:$media ($title)"
			}
		}

		# Return success
		return 0
	} else {
		# Return an error, so the help message will be shown
		return -1
	}
}

# ---------------------------------------------------------------------------- #
# Search an animated GIF on Giphy                                              #
# ---------------------------------------------------------------------------- #

proc ::ImageSearch::getGif {from_id chat_id msgid channel message parameter_start} {
	set max_file_size 20480000

	if {[set imagequery [string trim [string range $message $parameter_start end]]] ne ""} {
		if { [ catch {
			set imgresult [exec curl --tlsv1.2 -s -G https://api.giphy.com/v1/gifs/search -d api_key=$::ImageSearch::GiphyAPIkey -d q=$imagequery -d limit=1 -d rating=r]
		} ] } {
			putlog "::ImageSearch::getGif: cannot connect to api.giphy.com."
			return -1
		}

		if {[set meta_status [::libjson::getValue $imgresult ".meta.status//empty"]] ne "200"} {
			set meta_msg [::libjson::getValue $imgresult ".meta.msg//empty"]
			set reply [::msgcat::mc MSG_GIFSEARCH_ERROR "$meta_msg" "$meta_status"]
			::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid ""
			putchan $channel "$reply"
		} else {
			if {[set count [::libjson::getValue $imgresult ".pagination.count//empty"]] ne "1"} {
				set reply [::msgcat::mc MSG_IMAGESEARCH_NOTFOUND]
				::libtelegram::sendMessage $chat_id "$reply" "html" false $msgid ""
				putchan $channel "$reply"
			} else {
				set tmpfile "[file join /tmp [::libjson::getValue $imgresult ".data\[0\].id//empty"]].gif"
				set url [::libjson::getValue $imgresult ".data\[0\].url//empty"]
				set title [::libjson::getValue $imgresult ".data\[0\].title//empty"]
				set thumb [::libjson::getValue $imgresult ".data\[0\].images.original_still//empty"]
				set width [::libjson::getValue $imgresult ".data\[0\].images.original_still.width//empty"]
				set height [::libjson::getValue $imgresult ".data\[0\].images.original_still.height//empty"]
				set gifurl "[string map {https://giphy.com/gifs/ https://i.giphy.com/} $url].gif"
				set thumburl "[string map {https://giphy.com/gifs/ https://i.giphy.com/media/} $url]/giphy_s.gif"
				if { [ catch {
					set result [exec curl --tlsv1.2 --max-filesize $max_file_size --range 0-$max_file_size --silent --output $tmpfile --request GET $gifurl]
				} ] } {
					putlog "::ImageSearch::getGif: cannot download GIF file."
					return -1
				}
				::libtelegram::sendAnimation $chat_id "$tmpfile" "" "$width" "$height" "$thumburl" "<a href=\"$url\">Giphy: $title</a>" "html" false false $msgid ""
				file delete -force $tmpfile
				putchan $channel "$url (Giphy: $title)"
			}
		}

		# Return success
		return 0
	} else {
		# Return an error, so the help message will be shown
		return -1
	}
}

::telegram::addPublicCommand get ::ImageSearch::getImage "[::msgcat::mc MSG_IMAGESEARCH_HELP]"
::telegram::addPublicCommand gif ::ImageSearch::getGif "[::msgcat::mc MSG_GIFSEARCH_HELP]"
