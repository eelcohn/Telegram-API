# ---------------------------------------------------------------------------- #
# Telegram-API module v20180125 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Global internal variables                                                    #
# ---------------------------------------------------------------------------- #
namespace eval ::telegram {}
namespace eval ::telegram::cfg {}

set		tg_update_id			0
set		tg_bot_nickname			""
set		tg_bot_realname			""
set 		irc_bot_nickname		""
set		::telegram::cfg::userflags	"jlvck"
set		::telegram::cfg::cmdmodifier	"/"
array set	public_commands		{}
array set	private_commands	{}



# ---------------------------------------------------------------------------- #
# Initialization procedures                                                    #
# ---------------------------------------------------------------------------- #
# Initialize some variables (botnames)                                         #
# ---------------------------------------------------------------------------- #
proc initialize {} {
	global tg_bot_nickname tg_bot_realname irc_bot_nickname nick

	set result [::libtelegram::getMe]

	if {[::libjson::getValue $result ".ok"] ne "true"} {
		putlog "Telegram-API: bad result from getMe method: [::libjson::getValue $result ".description"]"
		utimer $tg_poll_freq tg2irc_pollTelegram
	}

	set tg_bot_nickname [::libjson::getValue $result ".result.username"]
	set tg_bot_realname [concat [::libjson::getValue $result ".result.first_name//empty"] [::libjson::getValue $result ".result.last_name//empty"]]
	set irc_bot_nickname "$nick"
}



# ---------------------------------------------------------------------------- #
# Procedures for sending data from IRC to Telegram                             #
# ---------------------------------------------------------------------------- #
# Send a message from IRC to Telegram                                          #
# ---------------------------------------------------------------------------- #
proc irc2tg_sendMessage {nick uhost hand channel msg} {
	global tg_channels

	# Only send a message to the Telegram group if the 'voice'-flag is set in the user flags variable
	if {[string match "v" $::telegram::cfg::userflags]} {
		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_MSGSENT "$nick" "[url_encode $msg]"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone joined an IRC channel              #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickJoined {nick uhost handle channel} {
	global irc_bot_nickname serveraddress
	global tg_channels

	# Only send a join message to the Telegram group if the 'join'-flag is set in the user flags variable
	if {[string match "j" $::telegram::cfg::userflags]} {
		if {$nick eq $irc_bot_nickname} {
			return 0
		}

		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$channel eq $tg_channel} {
				if {![validuser $nick]} {
					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKJOINED "$nick" "$serveraddress/$channel" "$channel"]
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone has left an IRC channel            #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickLeft {nick uhost handle channel message} {
	global  serveraddress tg_channels

	# Only send a leave message to the Telegram group if the 'leave'-flag is set in the user flags variable
	if {[string match "l" $::telegram::cfg::userflags]} {
		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$channel eq $tg_channel} {
				if {![validuser $nick]} {
					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKLEFT "$nick" "$serveraddress/$channel" "$channel" "$message"]
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Send an action from an IRC user to Telegram                                  #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickAction {nick uhost handle dest keyword message} {
	global tg_channels
	
	# Only send an action message to the Telegram group if the 'voice'-flag is set in the user flags variable
	if {[string match "v" $::telegram::cfg::userflags]} {
		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$dest eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that an IRC nickname has been changed           #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickChange {nick uhost handle channel newnick} {
	global tg_channels

	# Only send a nick change message to the Telegram group if the 'change'-flag is set in the user flags variable
	if {[string match "c" $::telegram::cfg::userflags]} {
		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKCHANGE "$nick" "$newnick"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that the topic of an IRC channel has changed    #
# ---------------------------------------------------------------------------- #
proc irc2tg_topicChange {nick uhost handle channel topic} {
	global serveraddress tg_channels

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {$nick ne "*"} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_TOPICCHANGE "$nick" "$serveraddress/$channel" "$channel" "$topic"]
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
	global tg_channels

	# Only send a kick message to the Telegram group if the 'kick'-flag is set in the user flags variable
	if {[string match "k" $::telegram::cfg::userflags]} {
		foreach {chat_id tg_channel} [array get tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_KICK "$nick" "$target" "$channel" "$reason"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that a channel's mode has changed               #
# ---------------------------------------------------------------------------- #
proc irc2tg_modeChange {nick uhost hand channel mode target} {
	global irc_bot_nickname tg_channels

	# Don't send mode changes to the Telegram if the bot just joined the IRC channel
	if {$nick eq $irc_bot_nickname} {
#		if {$::server-online+30 < [clock seconds]} {
			putlog "$irc_bot_nickname changes mode $mode at [clock seconds] (serveronline=$::server-online)"
			return 0
#		}
	}

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
#			::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_MODECHANGE "$nick" "$channel" "$mode"]
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
	global tg_bot_id tg_bot_token tg_update_id tg_poll_freq tg_channels utftable irc_bot_nickname colorize_nicknames

	# Check if the bot has already joined a channel
	if { [botonchan] != 1 } {
		putlog "Telegram-API: Not connected to IRC, skipping"
		# Dont go into the function but plan the next one
		utimer $tg_poll_freq tg2irc_pollTelegram
		return -1
	}

	# Poll the Telegram API for updates
	set result [::libtelegram::getUpdates $tg_update_id]

	# Check if we got a result
	if {$result == -1} {
		# Dont go into the parsing process but plan the next polling
		utimer $tg_poll_freq tg2irc_pollTelegram
 		return -2
	}

	# Check if the result was valid
	if {[::libjson::getValue $result ".ok"] ne "true"} {
		# Dont go into the parsing process but plan the next polling
		putlog "Telegram-API: bad result from getUpdates method: [::libjson::getValue $result ".description"]"
		utimer $tg_poll_freq tg2irc_pollTelegram
		return -3
	}

	# Iterate through each status update
	foreach tg_update_id [::libjson::getValue $result ".result\[\].update_id"] {
		set msg [::libjson::getValue $result ".result\[\] \| select(.update_id == $tg_update_id)"]
		set msgtype [::libjson::getValue $msg ". | keys\[\] | select(. != \"update_id\")"]

 		switch [::libjson::getValue $msg ".$msgtype.chat.type"] {
			"private" {
				# Record is a private chat record...
				if {[::libjson::hasKey $msg ".message.text"]} {
					set txt [remove_slashes [utf2ascii [::libjson::getValue $msg ".message.text"]]]
					set msgid [::libjson::getValue $msg ".message.message_id"]
					set fromid [::libjson::getValue $msg ".message.from.id"]

					tg2irc_privateCommands "$fromid" "$msgid" "$txt"
				}
			}

			"group" -
			"supergroup" -
			"channel" {
				# Record is a group, supergroup or channel record...
				set chatid [::libjson::getValue $msg ".$msgtype.chat.id"]
				set name [utf2ascii [::libjson::getValue $msg ".$msgtype.from.username"]]
				if {$name == "null" } {
					set name [utf2ascii [concat [::libjson::getValue $msg ".$msgtype.from.first_name//empty"] [::libjson::getValue $msg ".$msgtype.from.last_name//empty"]]]
				}

				if {$colorize_nicknames == "true"} {
					set name "\003[getColorFromString $name]$name\003"
				}

				# Check if this message is a reply to a previous message
				if {[::libjson::hasKey $msg ".$msgtype.reply_to_message"]} {
					set replyname [::libjson::getValue $msg ".$msgtype.reply_to_message.from.username"]
					if {$replyname == "null" } {
						set replyname [utf2ascii [concat [::libjson::getValue $msg ".$msgtype.reply_to_message.from.first_name//empty"] [::libjson::getValue $msg ".$msgtype.reply_to_message.from.last_name//empty"]]]
					}
					if {$colorize_nicknames == "true"} {
						set replyname "\003[getColorFromString $replyname]$replyname\003"
					} 
				}

				# Check if this message is a forwarded message
				if {[::libjson::hasKey $msg ".$msgtype.forward_from"]} {
					set forwardname [::libjson::getValue $msg ".$msgtype.forward_from.username"]
					if {$forwardname == "null" } {
						set forwardname [utf2ascii [concat [::libjson::getValue $msg ".$msgtype.forward_from.first_name//empty"] [::libjson::getValue $msg ".$msgtype.forward_from.last_name//empty"]]]
					}
					if {$colorize_nicknames == "true"} {
						set forwardname "\003[getColorFromString $forwardname]$forwardname\003"
					} 
				}

				# Check if a text message has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.text"]} {
					set txt [utf2ascii [::libjson::getValue $msg ".$msgtype.text"]]

					# Modify text if it is a reply-to or forwarded from
					if {[::libjson::hasKey $msg ".$msgtype.reply_to_message"]} {
						set replytomsg [utf2ascii [::libjson::getValue $msg ".$msgtype.reply_to_message.text"]]
						set txt "[::msgcat::mc MSG_TG_MSGREPLYTOSENT "$txt" "$replyname" "$replytomsg"]"
					} elseif {[::libjson::hasKey $msg ".$msgtype.forward_from"]} {
						set txt "[::msgcat::mc MSG_TG_MSGFORWARDED "$txt" "$forwardname"]"
					} 

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							foreach line [split [string map {\\n \n} $txt] "\n"] {
								putchan $irc_channel [::msgcat::mc MSG_TG_MSGSENT "$name" "[remove_slashes $line]"]
								if {[string match -nocase "*http://?*" $line] || [string match -nocase "*https://?*" $line] || [string match -nocase "*www.?*" $line]} {
									putchan $irc_channel [getWebsiteTitle $line]
								}
							}
							if {[string index $txt 0] eq $::telegram::cfg::cmdmodifier} {
								set msgid [::libjson::getValue $msg ".$msgtype.message_id"]
								tg2irc_botCommands "$tg_chat_id" "$msgid" "$irc_channel" "$txt"
							}
						}
					}
				}

				# Check if audio has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.audio"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.audio.file_id"]
					set tg_performer [::libjson::getValue $msg ".$msgtype.audio.performer"]
					set tg_title [::libjson::getValue $msg ".$msgtype.audio.title"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.audio.duration"]
					if {$tg_duration eq ""} {
						set tg_duration "0"
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_AUDIOSENT "$name" "$tg_performer" "$tg_title" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if a document has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.document"]} {
					set tg_file_id [::libjson::getValue $msg  ".$msgtype.document.file_id"]
					set tg_file_name [::libjson::getValue $msg ".$msgtype.document.file_name"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.document.file_size"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_DOCSENT " $name" "$tg_file_name" "$tg_file_size" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.photo"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.photo\[0\].file_id"]
					if {[::libjson::hasKey $msg ".$msgtype.caption"]} {
						set caption " ([remove_slashes [utf2ascii [::libjson::getValue $msg ".$msgtype.photo\[0\].caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PHOTOSENT "$name" "$caption" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if a sticker has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.sticker"]} {
					set emoji [::libjson::getValue $msg ".$msgtype.thumb.file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_STICKERSENT "$name" "[sticker2ascii $emoji]"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.video"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.video.file_id"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.video.duration"]
					if {$tg_duration eq "null"} {
						set tg_duration "0"
					}

					if {[::libjson::hasKey $msg ".$msgtype.video.caption"]} {
						set caption " ([utf2ascii [remove_slashes [::libjson::getValue $msg ".$msgtype.video.caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_VIDEOSENT "$name" "$caption" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if a voice object has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.voice"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.voice.file_id"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.voice.duration"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.voice.file_size"]
					if {$tg_duration eq ""} {
						set tg_duration "0"
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_VOICESENT "$name" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_file_size" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if a contact has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.contact"]} {
					set tg_phone_number [::libjson::getValue $msg ".$msgtype.contact.phone_number"]
					set tg_first_name [::libjson::getValue $msg ".$msgtype.contact.first_name"]
					set tg_last_name [::libjson::getValue $msg ".$msgtype.contact.last_name"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_CONTACTSENT "$name" "$tg_phone_number" "$tg_first_name" "$tg_last_name"]
						}
					}
				}

				# Check if a location has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.location"]} {
					# Check if a venue has been sent to the Telegram group
					if {[::libjson::hasKey $msg ".$msgtype.venue"]} {
						set tg_location [::libjson::getValue $msg ".$msgtype.venue.location"]
						set tg_title [::libjson::getValue $msg ".$msgtype.venue.title"]
						set tg_address [::libjson::getValue $msg ".$msgtype.venue.address"]
						set tg_foursquare_id [::libjson::getValue $msg ".$msgtype.venue.foursquare_id"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [::msgcat::mc MSG_TG_VENUESENT "$name" "$tg_location" "$tg_title" "$tg_address" "$tg_foursquare_id"]
							}
						}
					} else {
					# Not a venue, so it must be a location
						set tg_longitude [::libjson::getValue $msg ".$msgtype.location.longitude"]
						set tg_latitude [::libjson::getValue $msg ".$msgtype.location.latitude"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [::msgcat::mc MSG_TG_LOCATIONSENT "$name" "$tg_longitude" "$tg_latitude"]
							}
						}
					}
				}

				# Check if someone has been added to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_member"]} {
					set new_chat_member [concat [::libjson::getValue $msg ".$msgtype.new_chat_member.first_name"] [::libjson::getValue $msg ".$msgtype.new_chat_member.last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $new_chat_member} {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERJOINED "[utf2ascii $name]"]
							} else {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERADD "[utf2ascii $name]" "[utf2ascii $new_chat_member]"]
							}
						}
					}
				}

				# Check if someone has been removed from the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.left_chat_member"]} {
					set left_chat_member [concat [::libjson::getValue $msg ".$msgtype.left_chat_member.first_name"] [::libjson::getValue $msg ".$msgtype.left_chat_member.last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $left_chat_member} {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERLEFT "[utf2ascii $name]"]
							} else {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERREMOVED "[utf2ascii $name]" "[utf2ascii $left_chat_member]"]
							}
						}
					}
				}

				# Check if the title of the Telegram group chat has changed
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_title"]} {
					set chat_title [::libjson::getValue $msg ".$msgtype.new_chat_title"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_CHATTITLE "[utf2ascii $name]" "[utf2ascii $chat_title]"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has changed
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_photo"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.new_chat_photo\[0\].file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PICCHANGE "[utf2ascii $name]" "$irc_bot_nickname" "$tg_file_id"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has been deleted
				if {[::libjson::hasKey $msg ".$msgtype.delete_chat_photo"]} {
					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PICDELETE "[utf2ascii $name]"]
						}
					}
				}

				# Check if the group is migrated to a supergroup
				if {[::libjson::hasKey $msg ".$msgtype.migrate_to_chat_id"]} {
					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_GROUPMIGRATED "[utf2ascii $name]"]
						}
					}
				}
			}

			default {
				# Handle any unknown messages
				putlog "Unknown message received: $msg"
			}
		}
	}
	incr tg_update_id

	# ...and set a timer so it triggers the next poll
	utimer $tg_poll_freq tg2irc_pollTelegram
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc tg2irc_botCommands {chat_id msgid channel message} {
	global serveraddress tg_bot_nickname tg_bot_realname irc_bot_nickname public_commands

	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	if {[string match -nocase "@*" [string range $message $parameter_start end]]} {
		if {![string match -nocase "@$tg_bot_realname*" [string range $message $parameter_start end]]} {
			return
		}
	}

	::libtelegram::sendChatAction $chat_id "typing"

	switch $command {
		"help" {
			set response "[::msgcat::mc MSG_BOT_HELP "$irc_bot_nickname"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"irctopic" {
			set response "[::msgcat::mc MSG_BOT_TG_TOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircuser" {
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

		"ircusers" {
			set response "[::msgcat::mc MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[chanlist $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		default {
			foreach {cmd prc} [array get public_commands] {
				if {$command == $cmd} {
					$prc $chat_id $msgid $channel $message $parameter_start
					return
				}
			}

			::libtelegram::sendMessage $chat_id $msgid "markdown" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
			putchan $channel "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		}
	}
}

proc add_public_command {keyword procedure} {
	global public_commands

	set public_commands($keyword) $procedure
}

proc del_public_command {keyword} {
	global public_commands

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
	global timeformat tg_bot_nickname

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
#				::libtelegram::sendMessage $from_id $msgid "markdown" "[::msgcat::mc MSG_BOT_PASSWORDSET "$tg_bot_nickname"]"
#			}

			# Check if the password matches
			if {[passwdok $irchandle $ircpassword]} {
				setuser $irchandle XTRA "TELEGRAM_USERID" "[string range $from_id 0 12]"
#				setuser $irchandle XTRA "IRL" "[string range $first_name 0 159] [string range $last_name 0 159]"

				# Lookup the last login time
				set lastlogin [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"]
				if {$lastlogin == ""} {
					# First login of this user, so set LASTLOGOUT and LASTUSERID to defaults
					set lastlogin "[::msgcat::mc MSG_BOT_FIRSTLOGIN "$tg_bot_nickname"]"
					setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "0"
					setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "0"
				} else {
					# Prepare string with last login time
					set lastlogin "[::msgcat::mc MSG_BOT_LASTLOGIN "$tg_bot_nickname" "[clock format $lastlogin -format $timeformat]"]"
				}

				# ...and set the last login time to the current time
				setuser $irchandle XTRA "TELEGRAM_LASTLOGIN" "[clock seconds]"

				# Set the Telegram account creation date if this is the first time the user logs in
				if {[getuser $irchandle XTRA "TELEGRAM_CREATED"] == ""} {
					setuser $irchandle XTRA "TELEGRAM_CREATED" "[clock seconds]"
				}
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERLOGIN "$tg_bot_nickname" "$irchandle"]\n\n $lastlogin"
			} else {
				# Username/password combo doesn't match
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERPASSWRONG]"
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
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERLOGOUT "$irchandle" "$from_id"]"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_NOTLOGGEDIN]"
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
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERINFO "$irchandle" "$from_id" "$tg_lastlogin" "$tg_lastlogout" "$tg_lastuserid" "$tg_created" "$irc_created" "$irc_laston" "irc_hosts" "$irc_info"]"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_NOTLOGGEDIN]"
			}
		}

		"help" {
			::libtelegram::sendMessage $from_id $msgid "html" "Available commands are:\n login <username> <password>\n logout\n myinfo\n help\n"
		}

		default {
			::libtelegram::sendMessage $from_id $msgid "markdown" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
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

	foreach {utfstring stickerdesc} [array get stickertable] {
		set txt [string map -nocase [concat $utfstring $stickerdesc] $txt]
	}
	if {$stickerdesc eq ""} {
		return [::msgcat::mc MSG_TG_UNKNOWNSTICKER]
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
	if {$titlestart eq -1} {
		return "No title available"
	} else {
		set titlestart [string first ">" $result $titlestart]
		set titleend [string first "</title>" $result $titlestart]
		return [string range $result $titlestart+1 $titleend-1]
	}
}



# ---------------------------------------------------------------------------- #
# Start of main code                                                           #
# ---------------------------------------------------------------------------- #
# Start bot by loading Telegram modules, bind actions and do a Telegram poll   #
# ---------------------------------------------------------------------------- #

set scriptdir [file dirname [info script]]

package require msgcat

source "[file join $scriptdir lib libjson.tcl]"
source "[file join $scriptdir lib libtelegram.tcl]"
source "[file join $scriptdir Telegram-API-config.tcl]"
source "[file join $scriptdir utftable.tcl]"

::msgcat::mclocale $locale
::msgcat::mcload "[file join $scriptdir lang]"

foreach module [glob -nocomplain -dir "[file join $scriptdir modules]" *.tcl] {
	source $module
}

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

putlog "Script loaded: Telegram-API.tcl ($tg_bot_nickname)"
