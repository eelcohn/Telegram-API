# ---------------------------------------------------------------------------- #
# Soundcloud module for Eggdrop with the Telegram-API module v20180211         #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

source "[file join [file dirname [info script]] Soundcloud.conf]"

# ---------------------------------------------------------------------------- #
# Soundcloud procedures                                                        #
# ---------------------------------------------------------------------------- #
# Search a track on Soundcloud                                                 #
# ---------------------------------------------------------------------------- #

proc soundcloud_getTrack {chat_id msgid channel message parameter_start} {
	if {[set query [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]] ne ""} {
		if { [ catch {
			set result [exec curl --tlsv1.2 -s -X GET https://api.soundcloud.com/tracks.json?client_id=4346c8125f4f5c40ad666bacd8e96498&q=$query&limit=1]
		} ] } {
			putlog "Soundcloud.tcl: cannot connect to api.soundcloud.com using tracks.json method."
			return -1
		}

		if {[::libjson::getValue $result "total"] eq "0"} {
			set url "[::msgcat::mc MSG_SOUNDCLOUD_NOTFOUND]"
		} else {
			if {[set url [::libjson::getValue $result "permalink_url"]} eq -1} {
				set url "[::msgcat::mc MSG_SOUNDCLOUD_NOVALID]"
			}
		}

		::libtelegram::sendMessage $chat_id $msgid "html" "$url"
		putchan $channel "[strip_html $url]"

		return 0
	} else {
		return -1
	}
}

::telegram::addPublicCommand soundcloud soundcloud_getTrack "[::msgcat::mc MSG_SOUNDCLOUD_HELP]"
