# ---------------------------------------------------------------------------- #
# IRC helper module for Eggdrop with the Telegram-API module v20180211         #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

proc ::telegram::irctopic {chat_id msgid channel message parameter_start} {
	global serveraddress

	set response "[::msgcat::mc MSG_BOT_IRCTOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
	::libtelegram::sendMessage $chat_id $msgid "html" "$response"
	putchan $channel "[strip_html $response]"
}

proc ::telegram::ircuser {chat_id msgid channel message parameter_start} {
	set handle [string trim [string range $message $parameter_start end]]

	if {$handle != ""} {
  	if {[onchan $handle $channel]} {
			set online_since [getchanjoin $handle $channel]
			set response "[::msgcat::mc MSG_BOT_IRCUSER "$handle" "$online_since" "$serveraddress/$channel" "$channel" "[getchanhost $handle $channel]"]"
		} else {
			set response "[::msgcat::mc MSG_BOT_TG_UNKNOWNUSER "$handle" "$serveraddress/$channel" "channel"]"
		}
	} else {
		set response [::msgcat::mc MSG_BOT_HELP_IRCUSER]
	}
	::libtelegram::sendMessage $chat_id $msgid "html" "$response"
	putchan $channel "[strip_html $response]"
}

proc ::telegram::ircusers {chat_id msgid channel message parameter_start} {
	set response "[::msgcat::mc MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[string map {" " "\n"} [chanlist $channel]]"]"
	::libtelegram::sendMessage $chat_id $msgid "html" "$response"
	putchan $channel "[strip_html $response]"
}

::telegram::addPublicCommand irctopic ::telegram::irctopic ": Show the topic for the IRC channel(s) linked to this Telegram group."
::telegram::addPublicCommand ircuser ::telegram::ircuser ": Show info about an user on IRC."
::telegram::addPublicCommand ircusers ::telegram::ircusers ": Show all users on the IRC channel(s) linked to this Telegram group."
