# ---------------------------------------------------------------------------- #
# Telegram-API module v20180118 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Global internal variables                                                    #
# ---------------------------------------------------------------------------- #
set		tg_update_id		0
set		tg_botname		""
set		tg_bot_username		""
set 		irc_botname		""
array set	public_commands		{	{get}		{imagesearch_getImage}
						{locate}	{openstreetmaps_getLocation}
						{spotify}	{spotify_getTrack}
						{soundcloud}	{soundcloud_getTrack}
						{psn}		{psn_getPSNInfo}
						{quote}		{quotes_getQuote}
						{addquote}	{quotes_addQuote}
					}
array set	private_commands	{}



# ---------------------------------------------------------------------------- #
# Initialization procedures                                                    #
# ---------------------------------------------------------------------------- #
# Initialize some variables (botnames)                                         #
# ---------------------------------------------------------------------------- #
proc initialize {} {
	global tg_botname tg_bot_username irc_botname nick

	set result [::libtelegram::getMe]

	if {[::libjson::getValue $result ".ok"] ne "true"} {
		putlog "Telegram-API: bad result from getMe method: [::libjson::getValue $result ".description"]"
		utimer $tg_poll_freq tg2irc_pollTelegram
	}

	set tg_botname [::libjson::getValue $result ".result.username"]
	set tg_bot_username [::libjson::getValue $result ".result.first_name"]
	set irc_botname "$nick"
}



# ---------------------------------------------------------------------------- #
# Procedures for sending data from IRC to Telegram                             #
# ---------------------------------------------------------------------------- #
# Send a message from IRC to Telegram                                          #
# ---------------------------------------------------------------------------- #
proc irc2tg_sendMessage {nick uhost hand channel msg} {
	global tg_channels MSG_IRC_MSGSENT

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_MSGSENT "$nick" "[url_encode $msg]"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Let the Telegram group(s) know that someone joined an IRC channel            #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickJoined {nick uhost handle channel} {
	global irc_botname serveraddress
	global tg_channels MSG_IRC_NICKJOINED

	if {$nick eq $irc_botname} {
		return 0
	}

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {![validuser $nick]} {
				::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKJOINED "$nick" "$serveraddress/$channel" "$channel"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Let the Telegram group(s) know that someone has left an IRC channel          #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickLeft {nick uhost handle channel message} {
	global  serveraddress tg_channels MSG_IRC_NICKLEFT

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {![validuser $nick]} {
				::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKLEFT "$nick" "$serveraddress/$channel" "$channel" "$message"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Send an action from an IRC user to Telegram                                  #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickAction {nick uhost handle dest keyword message} {
	global tg_channels MSG_IRC_NICKACTION
	
	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$dest eq $tg_channel} {
			::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that an IRC nickname has been changed           #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickChange {nick uhost handle channel newnick} {
	global tg_channels MSG_IRC_NICKCHANGE

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKCHANGE "$nick" "$newnick"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that the topic of an IRC channel has changed    #
# ---------------------------------------------------------------------------- #
proc irc2tg_topicChange {nick uhost handle channel topic} {
	global serveraddress tg_channels MSG_IRC_TOPICCHANGE

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {$nick ne "*"} {
				::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_TOPICCHANGE "$nick" "$serveraddress/$channel" "$channel" "$topic"]
				::libtelegram::setChatTitle $chat_id $topic
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone has been kicked from the channel   #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickKicked {nick uhost handle channel target reason} {
	global tg_channels MSG_IRC_KICK

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_KICK "$nick" "$target" "$channel" "$reason"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that a channel's mode has changed               #
# ---------------------------------------------------------------------------- #
proc irc2tg_modeChange {nick uhost hand channel mode target} {
	global irc_botname tg_channels MSG_IRC_MODECHANGE

	# Don't send mode changes to the Telegram if the bot just joined the IRC channel
	if {$nick eq $irc_botname} {
#		if {$::server-online+30 < [clock seconds]} {
			putlog "$irc_botname changes mode $mode at [clock seconds] (serveronline=$::server-online)"
			return 0
#		}
	}

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
#			::libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_MODECHANGE "$nick" "$channel" "$mode"]
		}
	}
	return 0
}



# ---------------------------------------------------------------------------- #
# Procedures for reading data from the Telegram servers                        #
# ---------------------------------------------------------------------------- #
# Poll the Telegram server for updates                                         #
# ---------------------------------------------------------------------------- #
proc tg2irc_pollTelegram {} {
	global tg_bot_id tg_bot_token tg_update_id tg_poll_freq tg_channels utftable irc_botname colorize_nicknames
	global MSG_TG_MSGSENT MSG_TG_AUDIOSENT MSG_TG_PHOTOSENT MSG_TG_DOCSENT MSG_TG_STICKERSENT MSG_TG_VIDEOSENT MSG_TG_VOICESENT MSG_TG_CONTACTSENT MSG_TG_LOCATIONSENT MSG_TG_VENUESENT MSG_TG_USERJOINED MSG_TG_USERADD MSG_TG_USERLEFT MSG_TG_USERREMOVED MSG_TG_CHATTITLE MSG_TG_PICCHANGE MSG_TG_PICDELETE MSG_TG_UNIMPL

	# Check if the bot has already joined a channel
	if { [botonchan] != 1 } {
		putlog "Telegram-API: Not connected to IRC, skipping"
		# Dont go into the function but plan the next one
		utimer $tg_poll_freq tg2irc_pollTelegram
		return 1
	}

	# Poll the Telegram API for updates
	set result [::libtelegram::getUpdates $tg_update_id]

	# Check if we got a result
	if {$result == -1} {
		# Dont go into the parsing process but plan the next polling
		utimer $tg_poll_freq tg2irc_pollTelegram
 		return -1
	}

	# Check if the result was valid
	if {[::libjson::getValue $result ".ok"] ne "true"} {
		# Dont go into the parsing process but plan the next polling
		putlog "Telegram-API: bad result from getUpdates method: [::libjson::getValue $result ".description"]"
		utimer $tg_poll_freq tg2irc_pollTelegram
		return -1
	}

	# Result was valid, clear the tg_update_id variable for now
	set tg_update_id 0
 
	foreach u_id [::libjson::getValue $result ".result\[\].update_id"] {
		set msg [::libjson::getValue $result ".result\[\] \| select(.update_id == $u_id)"]

 		switch [::libjson::getValue $msg ".message.chat.type"] {
			# Check if this record is a private chat record...
			"private" {
				# Should be ::libjson::hasKey
				if {[::libjson::getValue $msg ".message.text"] != "null"} {
					set txt [remove_slashes [utf2ascii [::libjson::getValue $msg ".message.text"]]]
					set msgid [::libjson::getValue $msg ".message.message_id"]
					set fromid [::libjson::getValue $msg ".message.from.id"]

					tg2irc_privateCommands "$fromid" "$msgid" "$txt"
				}
			}

			# Check if this record is a group or supergroup chat record...
			"supergroup" -
			"group" {
				set chatid [::libjson::getValue $msg ".message.chat.id"]
				set name [utf2ascii [::libjson::getValue $msg ".message.from.username"]]
				if {$name == "null" } {
					set name [utf2ascii [concat [::libjson::getValue $msg ".message.from.first_name"] [::libjson::getValue $msg ".message.from.last_name"]]]
				}

				if {$colorize_nicknames == "true"} {
					set name "\003[getColorFromString $name]$name\003"
				}

				# Check if this message is a reply to a previous message
				if {[::libjson::hasKey $msg ".message.reply_to_message"]} {
					set replyname [::libjson::getValue $msg ".message.reply_to_message.from.username"]
					if {$replyname == "" } {
						set replyname [utf2ascii [concat [::libjson::getValue $msg ".message.reply_to_message.from.first_name"] [::libjson::getValue $msg ".message.reply_to_message.from.last_name"]]]
					}
					if {$colorize_nicknames == "true"} {
						set replyname "\003[getColorFromString $replyname]$replyname\003"
					} 
				}

				# Check if a text message has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.text"]} {
					set txt [utf2ascii [::libjson::getValue $msg ".message.text"]]

					# Modify text if it is a reply-to
					if {[::libjson::hasKey $msg ".message.reply_to_message"]} {
						set txt "$txt (in reply to $replyname)"
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							foreach line [split [string map {\\n \n} $txt] "\n"] {
								putchan $irc_channel [format $MSG_TG_MSGSENT "$name" "[remove_slashes $line]"]
								if {[string match -nocase "*http://?*" $line] || [string match -nocase "*https://?*" $line] || [string match -nocase "*www.?*" $line]} {
									putchan $irc_channel [getWebsiteTitle $line]
								}
							}
							if {[string index $txt 0] eq "/"} {
								set msgid [::libjson::getValue $msg ".message.message_id"]
								tg2irc_botCommands "$tg_chat_id" "$msgid" "$irc_channel" "$txt"
							}
						}
					}
				}

				# Check if audio has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.audio"]} {
					set tg_file_id [::libjson::getValue $msg ".message.audio.file_id"]
					set tg_performer [::libjson::getValue $msg ".message.audio.performer"]
					set tg_title [::libjson::getValue $msg ".message.audio.title"]
					set tg_duration [::libjson::getValue $msg ".message.audio.duration"]
					if {$tg_duration eq ""} {
						set tg_duration "0"
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_AUDIOSENT "$name" "$tg_performer" "$tg_title" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a document has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.document"]} {
					set tg_file_id [::libjson::getValue $msg  ".message.document.file_id"]
					set tg_file_name [::libjson::getValue $msg ".message.document.file_name"]
					set tg_file_size [::libjson::getValue $msg ".message.document.file_size"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_DOCSENT " $name" "$tg_file_name" "$tg_file_size" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.photo"]} {
					set tg_file_id [::libjson::getValue $msg ".message.photo\[0\].file_id"]
					if {[::libjson::hasKey $msg ".result.message.caption"]} {
						# Bug: the object should really be "photo" and not ""
						set caption " ([remove_slashes [utf2ascii [::libjson::getValue $msg ".message.photo\[0\].caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PHOTOSENT "$name" "$caption" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a sticker has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.sticker"]} {
					set emoji [::libjson::getValue $msg ".message.thumb.file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_STICKERSENT "$name" "[sticker2ascii $emoji]"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.video"]} {
					set tg_file_id [::libjson::getValue $msg ".message.video.file_id"]
					set tg_duration [::libjson::getValue $msg ".message.video.duration"]
					if {$tg_duration eq "null"} {
						set tg_duration "0"
					}

					if {[::libjson::hasKey $msg ".message.video.caption"]} {
						set caption " ([utf2ascii [remove_slashes [::libjson::getValue $msg ".message.video.caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_VIDEOSENT "$name" "$caption" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a voice object has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.voice"]} {
					set tg_file_id [::libjson::getValue $msg ".message.voice.file_id"]
					set tg_duration [::libjson::getValue $msg ".message.voice.duration"]
					set tg_file_size [::libjson::getValue $msg ".message.voice.file_size"]
					if {$tg_duration eq ""} {
						set tg_duration "0"
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_VOICESENT "$name" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_file_size" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a contact has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.contact"]} {
					set tg_phone_number [::libjson::getValue $msg ".message.contact.phone_number"]
					set tg_first_name [::libjson::getValue $msg ".message.contact.first_name"]
					set tg_last_name [::libjson::getValue $msg ".message.contact.last_name"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_CONTACTSENT "$name" "$tg_phone_number" "$tg_first_name" "$tg_last_name"]
						}
					}
				}

				# Check if a location has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".message.location"]} {
					# Check if a venue has been sent to the Telegram group
					if {[::libjson::hasKey $msg ".message.venue"]} {
						set tg_location [::libjson::getValue $msg ".message.venue.location"]
						set tg_title [::libjson::getValue $msg ".message.venue.title"]
						set tg_address [::libjson::getValue $msg ".message.venue.address"]
						set tg_foursquare_id [::libjson::getValue $msg ".message.venue.foursquare_id"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [format $MSG_TG_VENUESENT "$name" "$tg_location" "$tg_title" "$tg_address" "$tg_foursquare_id"]
							}
						}
					} else {
					# Not a venue, so it must be a location
						set tg_longitude [::libjson::getValue $msg ".message.location.longitude"]
						set tg_latitude [::libjson::getValue $msg ".message.location.latitude"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [format $MSG_TG_LOCATIONSENT "$name" "$tg_longitude" "$tg_latitude"]
							}
						}
					}
				}

				# Check if someone has been added to the Telegram group
				if {[::libjson::hasKey $msg ".message.new_chat_member"]} {
					set new_chat_member [concat [::libjson::getValue $msg ".message.new_chat_member.first_name"] [::libjson::getValue $msg ".message.new_chat_member.last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $new_chat_member} {
								putchan $irc_channel [format $MSG_TG_USERJOINED "[utf2ascii $name]"]
							} else {
								putchan $irc_channel [format $MSG_TG_USERADD "[utf2ascii $name]" "[utf2ascii $new_chat_member]"]
							}
						}
					}
				}

				# Check if someone has been removed from the Telegram group
				if {[::libjson::hasKey $msg ".message.left_chat_member"]} {
					set left_chat_member [concat [::libjson::getValue $msg ".message.left_chat_member.first_name"] [::libjson::getValue $msg ".message.left_chat_member.last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $left_chat_member} {
								putchan $irc_channel [format $MSG_TG_USERLEFT "[utf2ascii $name]"]
							} else {
								putchan $irc_channel [format $MSG_TG_USERREMOVED "[utf2ascii $name]" "[utf2ascii $left_chat_member]"]
							}
						}
					}
				}

				# Check if the title of the Telegram group chat has changed
				if {[::libjson::hasKey $msg ".message.new_chat_title"]} {
					set chat_title [::libjson::getValue $msg ".message.new_chat_title"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_CHATTITLE "[utf2ascii $name]" "[utf2ascii $chat_title]"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has changed
				if {[::libjson::hasKey $msg ".message.new_chat_photo"]} {
					set tg_file_id [::libjson::getValue $msg ".message.new_chat_photo\[0\].file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PICCHANGE "[utf2ascii $name]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has been deleted
				if {[::libjson::hasKey $msg ".message.delete_chat_photo"]} {
					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PICDELETE "[utf2ascii $name]"]
						}
					}
				}
			}

			# Check if this record is a channel record
			"channel" {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Channel message received ($msg)"
					}
				}
			}

			# Handle any unknown messages
			default {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Unknown message received ($msg)"
					}
				}
			}
		}

		#If we are here everything goes fine
		# increment tg offset
		set tg_update_id $u_id
		incr tg_update_id
	}

	# ...and set a timer so it triggers the next poll
	utimer $tg_poll_freq tg2irc_pollTelegram
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc tg2irc_botCommands {chat_id msgid channel message} {
	global serveraddress tg_botname tg_bot_username irc_botname
	global MSG_BOT_HELP MSG_BOT_TG_TOPIC MSG_BOT_IRC_TOPIC MSG_BOT_HELP_IRCUSER MSG_BOT_IRCUSER MSG_BOT_TG_UNKNOWNUSER MSG_BOT_IRCUSERS MSG_BOT_UNKNOWNCMD

	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	if {[string match -nocase "@*" [string range $message $parameter_start end]]} {
		if {![string match -nocase "@$tg_bot_username*" [string range $message $parameter_start end]]} {
			return
		}
	}

	::libtelegram::sendChatAction $chat_id "typing"

	switch $command {
		"help" {
			set response "[format $MSG_BOT_HELP "$irc_botname"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"irctopic" {
			set response "[format $MSG_BOT_TG_TOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircuser" {
			set handle [string trim [string range $message $parameter_start end]]

			if {$handle != ""} {
				if {[onchan $handle $channel]} {
					set online_since [getchanjoin $handle $channel]
					set response "[format $MSG_BOT_IRCUSER "$handle" "$online_since" "$serveraddress/$channel" "$channel" "[getchanhost $handle $channel]"]"
				} else {
					set response "[format $MSG_BOT_TG_UNKNOWNUSER "$handle" "$serveraddress/$channel" "channel"]"
				}
			} else {
				set response $MSG_BOT_HELP_IRCUSER
			}
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircusers" {
			set response "[format $MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[chanlist $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"get" {
			imagesearch_getImage $chat_id $msgid $channel $message $parameter_start
		}

		"locate" {
			openstreetmaps_getLocation $chat_id $msgid $channel $message $parameter_start
		}

		"spotify" {
			spotify_getTrack $chat_id $msgid $channel $message $parameter_start
		}

		"soundcloud" {
			soundcloud_getTrack $chat_id $msgid $channel $message $parameter_start
		}

		"psn" {
			psn_getPSNInfo $chat_id $msgid $channel $message $parameter_start
		}

		"quote" {
			quotes_getQuote $chat_id $msgid $channel $message $parameter_start
		}

		"addquote" {
			quotes_addQuote $chat_id $msgid $channel $message $parameter_start
		}

		default {
			::libtelegram::sendMessage $chat_id $msgid "markdown" "$MSG_BOT_UNKNOWNCMD"
			putchan $channel "$MSG_BOT_UNKNOWNCMD"
		}
	}
}

proc add_public_command {keyword procedure} {
	set public_commands($keyword) $procedure
}

proc del_public_command {keyword} {
	if {[info exists $public_commands($keyword)]} {
		unset -nocomplain public_commands($keyword)
		return true
	} else {
		return false
	}
}

# ---------------------------------------------------------------------------- #
# Respond to private commands send by Telegram users                           #
# ---------------------------------------------------------------------------- #
proc tg2irc_privateCommands {from_id msgid message} {
	global MSG_BOT_PASSWORDSET MSG_BOT_USERLOGIN MSG_BOT_USERLOGOUT MSG_BOT_FIRSTLOGIN MSG_BOT_LASTLOGIN MSG_BOT_USERPASSWRONG MSG_BOT_USERLOGGEDINAS MSG_BOT_USERINFO MSG_BOT_NOTLOGGEDIN MSG_BOT_UNAUTHORIZED MSG_BOT_UNKNOWNCMD
	global timeformat tg_botname

	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	libtelegram::sendChatAction $from_id "typing"

	switch $command {
		"login" {
			set login_start [string wordend $message 1]
			set login_end [string wordend $message $login_start+1]

			set irchandle [string trim [string range $message $login_start $login_end]]
			set ircpassword [string trim [string range $message $login_end end]]

			# Set the password if this is the first time this user logs in
#			if {[getuser $irchandle PASS] == ""} {
#				setuser $irchandle PASS "$ircpassword"
#				::libtelegram::sendMessage $from_id $msgid "markdown" "[format $MSG_BOT_PASSWORDSET "$tg_botname"]"
#			}

			# Check if the password matches
			if {[passwdok $irchandle $ircpassword]} {
				setuser $irchandle XTRA "TELEGRAM_USERID" "[string range $from_id 0 12]"
#				setuser $irchandle XTRA "IRL" "[string range $first_name 0 159] [string range $last_name 0 159]"

				# Lookup the last login time
				set lastlogin [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"]
				if {$lastlogin == ""} {
					# First login of this user, so set LASTLOGOUT and LASTUSERID to defaults
					set lastlogin "[format $MSG_BOT_FIRSTLOGIN "$tg_botname"]"
					setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "0"
					setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "0"
				} else {
					# Prepare string with last login time
					set lastlogin "[format $MSG_BOT_LASTLOGIN "$tg_botname" "[clock format $lastlogin -format $timeformat]"]"
				}

				# ...and set the last login time to the current time
				setuser $irchandle XTRA "TELEGRAM_LASTLOGIN" "[clock seconds]"

				# Set the Telegram account creation date if this is the first time the user logs in
				if {[getuser $irchandle XTRA "TELEGRAM_CREATED"] == ""} {
					setuser $irchandle XTRA "TELEGRAM_CREATED" "[clock seconds]"
				}
				::libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERLOGIN "$tg_botname" "$irchandle"]\n\n $lastlogin"
			} else {
				# Username/password combo doesn't match
				::libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_USERPASSWRONG"
			}
		}

		"logout" {
			set irchandle ""

			# Look up the IRC handle for the Telegram user
			foreach user [userlist] {
				if {[getuser $user XTRA "TELEGRAM_USERID"] == "$from_id"} {
					set irchandle $user
				}
			}

			if {$irchandle != ""} {
				setuser $irchandle XTRA "TELEGRAM_USERID" ""
				setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "$from_id"
				setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "[clock seconds]"
				::libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERLOGOUT "$irchandle" "$from_id"]"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_NOTLOGGEDIN"
			}
		}

		# Show user information
		"myinfo" {
			set irchandle ""

			# Look up the IRC handle for the Telegram user
			foreach user [userlist] {
				if {[getuser $user XTRA "TELEGRAM_USERID"] == "$from_id"} {
					set irchandle $user
				}
			}

			if {$irchandle != ""} {
				set tg_lastlogin [clock format [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"] -format $timeformat]
				set tg_lastlogout [clock format [getuser $irchandle XTRA "TELEGRAM_LASTLOGOUT"] -format $timeformat]
				set tg_lastuserid [getuser $irchandle XTRA "TELEGRAM_LASTUSERID"]
				set tg_created [clock format [getuser $irchandle XTRA "TELEGRAM_CREATED"] -format $timeformat]
				set irc_created [clock format [getuser $irchandle XTRA "created"] -format $timeformat]
				set irc_laston [clock format [lindex [split [getuser $irchandle LASTON] " "] 0] -format $timeformat]
				set irc_hosts [getuser $irchandle HOSTS]
				set irc_info [getuser $irchandle INFO]
				putlog "$irc_hosts"
				::libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERINFO "$irchandle" "$from_id" "$tg_lastlogin" "$tg_lastlogout" "$tg_lastuserid" "$tg_created" "$irc_created" "$irc_laston" "irc_hosts" "$irc_info"]"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_NOTLOGGEDIN"
			}
		}

		"help" {
			::libtelegram::sendMessage $from_id $msgid "html" "Available commands are:\n login <username> <password>\n logout\n myinfo\n help\n"
		}

		default {
			::libtelegram::sendMessage $from_id $msgid "markdown" "$MSG_BOT_UNKNOWNCMD"
		}
	}
}



# ---------------------------------------------------------------------------- #
# Some general usage procedures
# ---------------------------------------------------------------------------- #
# Replace Escaped-Unicode characters to ASCII                                  #
# ---------------------------------------------------------------------------- #
proc utf2ascii {txt} {
	global utftable

	foreach {utfstring asciistring} [array get utftable] {
		set txt [string map -nocase [concat $utfstring $asciistring] $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Replace ASCII characters to Escaped-Unicode                                  #
# ---------------------------------------------------------------------------- #
proc ascii2utf {txt} {
	global utftable

	foreach {utfstring asciistring} [array get utftable] {
		set txt [string map [concat $asciistring $utfstring] $txt]
	}
	return [encoding convertto unicode $txt]
}

# ---------------------------------------------------------------------------- #
# Replace sticker code with ASCII code                                         #
# ---------------------------------------------------------------------------- #
proc sticker2ascii {txt} {
	global stickertable
	global MSG_TG_UNKNOWNSTICKER

	foreach {utfstring stickerdesc} [array get stickertable] {
		set txt [string map -nocase [concat $utfstring $stickerdesc] $txt]
	}
	if {$stickerdesc eq ""} {
		return $MSG_TG_UNKNOWNSTICKER
	}
	return $stickerdesc
}

# ---------------------------------------------------------------------------- #
# Remove HTML tags from a string                                               #
# ---------------------------------------------------------------------------- #
proc strip_html {htmlText} {
	regsub -all {<[^>]+>} $htmlText "" newText
	return $newText
}

# ---------------------------------------------------------------------------- #
# Remove double slashes from a string                                          #
# ---------------------------------------------------------------------------- #
proc remove_slashes {txt} {
	regsub -all {\\} $txt {} txt
	return $txt
}

# ---------------------------------------------------------------------------- #
# Add backslashes to [ and ] characters                                        #
# ---------------------------------------------------------------------------- #
proc escape_out_bracket {txt} {
	regsub -all {\[} $txt {\[} txt
#	regsub -all {\]} $txt {\]} txt
	return $txt
}

# ---------------------------------------------------------------------------- #
# Encode all except "unreserved" characters; use UTF-8 for extended chars.     #
# ---------------------------------------------------------------------------- #
proc url_encode {str} {
	set str [string map {"&" "&amp;" "<" "&lt;" ">" "&gt;"} $str]
	set uStr [encoding convertto utf-8 $str]
	set chRE {[^-A-Za-z0-9._~\n]};		# Newline is special case!
	set replacement {%[format "%02X" [scan "\\\0" "%c"]]}
	return [string map {"\n" "%0A"} [subst [regsub -all $chRE $uStr $replacement]]]
}

# ---------------------------------------------------------------------------- #
# Calculate an IRC color code for a nickname                                   #
# ---------------------------------------------------------------------------- #
proc getColorFromString {string} {
	# Set the seed for the calculation to 0x00
	set color 0x00

	# Exclusive-OR each character of the string with the seed
	foreach char [split $string ""] {
		set color [expr $color + [scan $char %c]]
	}

	# Return only values from 1 to 15
	return [expr [expr $color % 15] + 1]
}

# ---------------------------------------------------------------------------- #
# Get the title of a website for website previews on IRC                       #
# ---------------------------------------------------------------------------- #
proc getWebsiteTitle {url} {
	if { [ catch {
		set result [exec curl --tlsv1.2 --location -s -X GET $url]
	} ] } {
		return "No preview available"
	}

	set titlestart [string first "<title>" $result]
	set titleend [string first "</title>" $result]
	return [string range $result $titlestart+7 $titleend-1]
}



# ---------------------------------------------------------------------------- #
# Start of main code                                                           #
# ---------------------------------------------------------------------------- #
# Start bot by loading Telegram modules, bind actions and do a Telegram poll   #
# ---------------------------------------------------------------------------- #

set scriptdir [file dirname [info script]]

source "$scriptdir/lib/libjson.tcl"
source "$scriptdir/lib/libtelegram.tcl"
source "$scriptdir/Telegram-API-config.tcl"
source "$scriptdir/utftable.tcl"
source "$scriptdir/lang/Telegram-API.$language.tcl"

source "$scriptdir/modules/ImageSearch.tcl"
source "$scriptdir/modules/Locate.tcl"
source "$scriptdir/modules/PSN.tcl"
source "$scriptdir/modules/Quotes.tcl"
source "$scriptdir/modules/Soundcloud.tcl"
source "$scriptdir/modules/Spotify.tcl"

bind pubm - * irc2tg_sendMessage
bind join - * irc2tg_nickJoined
bind part - * irc2tg_nickLeft
bind sign - * irc2tg_nickLeft
bind ctcp - "ACTION" irc2tg_nickAction
bind nick - * irc2tg_nickChange
bind topc - * irc2tg_topicChange
bind kick - * irc2tg_nickKicked
bind mode - * irc2tg_modeChange

initialize

tg2irc_pollTelegram

putlog "Script loaded: Telegram-API.tcl ($tg_botname)"
