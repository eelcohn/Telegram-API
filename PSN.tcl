# ---------------------------------------------------------------------------- #
# Playstation Network module v0.1 for Eggdrop with the Telegram-API module     #
#                                                                              #
# written by Eelco Huininga 2016                                               #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #
# Playstation Network procedures                                               #
# ---------------------------------------------------------------------------- #
# Get player information from the PlayStation Network site                     #
# ---------------------------------------------------------------------------- #

proc psn_getPSNInfo {chat_id msgid channel message parameter_start} {
	global MSG_PSN_RESULT MSG_PSN_NOTFOUND

	tg_sendChatAction $chat_id "typing"

	set query [string map {" " "%20"} [string trim [string range $message $parameter_start end]]]
	set result [exec curl --tlsv1.2 -s -X GET https://my.playstation.com/$query]
	
	set start [string first "<img class=\"avatar\" alt=\"" $result]
	if {$start != -1} {
		set end [string first "\"" $result [expr $start+25]]
		set name [string range $result [expr $start+25] $end-1]

		set start [string first " src=\"" $result $end]
		set end [string first "\"" $result [expr $start+6]]
		set url [string range $result [expr $start+6] $end-1]

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

		set result [format "$MSG_PSN_RESULT" "$name%0A" "$level%0A" "$game1%0A" "$game2%0A" "$game3"]
#		set result "Player: $name%0ALevel: $level%0ARecently seen playing:%0A1. $game1%0A2. $game2%0a3. $game3"
		tg_sendPhoto $chat_id $msgid "https:$url" "$result"
		putchan $channel "Player: $name https:[strip_html $url]"
	} else {
		set result "$MSG_PSN_NOTFOUND"
		tg_sendReplyToMessage $chat_id $msgid "html" "$result"
		putchan $channel "[strip_html $result]"
	}
}
