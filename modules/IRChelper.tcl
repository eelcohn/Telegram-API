# ---------------------------------------------------------------------------- #
# IRC helper module for Eggdrop with the Telegram-API module v20180211         #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Shows the topic of an IRC channel                                            #
# ---------------------------------------------------------------------------- #
proc ::telegram::irctopic {chat_id msgid channel message parameter_start} {
	global serveraddress

	set response "[::msgcat::mc MSG_BOT_IRCTOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
	::libtelegram::sendMessage $chat_id $msgid "html" "$response"
	putchan $channel "[strip_html $response]"

	# Return success
	return 0
}

# ---------------------------------------------------------------------------- #
# Shows detailed information about an user on IRC                              #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircuser {chat_id msgid channel message parameter_start} {
	global serveraddress

	set handle [string trim [string range $message $parameter_start end]]

	if {$handle != ""} {
  		if {[onchan $handle $channel]} {
			set online_since [clock format [getchanjoin $handle $channel] -format $::telegram::timeformat]
			set response "[::msgcat::mc MSG_BOT_IRCUSER "$handle" "$online_since" "$serveraddress/$channel" "$channel" "[getchanhost $handle $channel]"]"
		} else {
			set response "[::msgcat::mc MSG_BOT_IRCUSERUNKNOWN "$handle" "$serveraddress/$channel" "$channel"]"
		}
		::libtelegram::sendMessage $chat_id $msgid "html" "$response"
		putchan $channel "[strip_html $response]"

		# Return success
		return 0
	} else {
		# Return an error, so the help message will be shown
		return -1
	}
}

# ---------------------------------------------------------------------------- #
# Shows all users on an IRC channel                                            #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircusers {chat_id msgid channel message parameter_start} {
	global serveraddress

	set response "[::msgcat::mc MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[string map {" " "\n"} [chanlist $channel]]"]"
	::libtelegram::sendMessage $chat_id $msgid "html" "$response"
	putchan $channel "[strip_html $response]"

	# Return success
	return 0
}

::telegram::addPublicCommand irctopic ::telegram::irctopic "[::msgcat::mc MSG_BOT_IRCTOPIC_HELP]"
::telegram::addPublicCommand ircuser ::telegram::ircuser "[::msgcat::mc MSG_BOT_IRCUSER_HELP]"
::telegram::addPublicCommand ircusers ::telegram::ircusers "[::msgcat::mc MSG_BOT_IRCUSERS_HELP]"
