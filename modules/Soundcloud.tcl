# ---------------------------------------------------------------------------- #
# Soundcloud module v0.1 for Eggdrop with the Telegram-API module v20180115    #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
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
	set query [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X GET https://api.soundcloud.com/tracks.json?client_id=4346c8125f4f5c40ad666bacd8e96498&q=$query&limit=1]
	} ] } {
		putlog "Soundcloud.tcl: cannot connect to api.soundcloud.com using tracks.json method."
		return -1
	}

	set url [::libjson::getValue $result "" "permalink_url"]

	libtelegram::sendMessage $chat_id $msgid "html" "$url"
	putchan $channel "[strip_html $url]"
}
