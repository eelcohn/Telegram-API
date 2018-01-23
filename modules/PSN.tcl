# ---------------------------------------------------------------------------- #
# Telegram-API Playstation Network module for Eggdrop v20180123                #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #

source "[file join [file dirname [info script]] PSN.conf]"

# ---------------------------------------------------------------------------- #
# Playstation Network procedures                                               #
# ---------------------------------------------------------------------------- #
# Get player information from the PlayStation Network site                     #
# ---------------------------------------------------------------------------- #

proc psn_getPSNInfo {chat_id msgid channel message parameter_start} {
	set query [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X GET https://my.playstation.com/$query]
	} ] } {
		putlog "PSN.tcl: cannot connect to my.playstation.com."
		return 1
	}

	set start [string first "<img class=\"avatar\" alt=\"" $result]
	if {$start != -1} {
		set end [string first "\"" $result [expr $start+25]]
		set name [string range $result [expr $start+25] $end-1]

		set start [string first " src=\"" $result $end]
		set end [string first "\"" $result [expr $start+6]]
		set userpic [string range $result [expr $start+6] $end-1]

		if {[string first "No data found" $result] != "-1"} {
			set response "Player: $name%0AThis player's profile is private."
		} else {
			set start [string first "<div class=\"quantity content level-num\">" $result]
			set end [string first "<" $result [expr $start+40]]
			set level [string range $result [expr $start+40] $end-1]

			set start [string first "<div class=\"trophy-image\">" $result]
			set start [string first "title=\"" $result $start]
			set end [string first "\"" $result [expr $start+7]]
			set game1 [string range $result [expr $start+7] $end-1]

			set start [string first "<div class=\"trophy-image\">" $result $start]
			set start [string first "title=\"" $result $start]
			set end [string first "\"" $result [expr $start+7]]
			set game2 [string range $result [expr $start+7] $end-1]

			set start [string first "<div class=\"trophy-image\">" $result $start]
			set start [string first "title=\"" $result $start]
			set end [string first "\"" $result [expr $start+7]]
			set game3 [string range $result [expr $start+7] $end-1]

			set response [::msgcat::mc MSG_PSN_RESULT "$name" "$level" "$game1" "$game2" "$game3"]
#			set response "Player: $name%0ALevel: $level%0ARecently seen playing:%0A1. $game1%0A2. $game2%0A3. $game3"
		}
		libtelegram::sendPhoto $chat_id $msgid "https:$userpic" "$response"
		putchan $channel "Player: $name https:[strip_html $userpic]"
	} else {
		set response "[::msgcat::mc MSG_PSN_NOTFOUND]"
		libtelegram::sendMessage $chat_id $msgid "html" "$response"
		putchan $channel "[strip_html $response]"
	}
}

add_public_command psn psn_getPSNInfo
