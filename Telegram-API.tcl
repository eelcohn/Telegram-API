# ---------------------------------------------------------------------------- #
# Telegram-API module v0.1 for Eggdrop                                         #
#                                                                              #
# written by Eelco Huininga 2016                                               #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #
set tg_bot_id			123456789
set tg_bot_token		AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345
set tg_poll_freq		5
set tg_owner_id			98765432
set tg_web_page_preview	false
set language			"english"

array set tg_channels {
	"-21436587"		"#lamer"
	"-171615141"		"#lamer-test"
}

# ---------------------------------------------------------------------------- #
# Global internal variables                                                    #
# ---------------------------------------------------------------------------- #
set tg_update_id	0
set tg_botname		""
set irc_botname		""



# ---------------------------------------------------------------------------- #
# Initialization procedures                                                    #
# ---------------------------------------------------------------------------- #
# Initialize some variables (botnames)                                         #
# ---------------------------------------------------------------------------- #
proc initialize {} {
	global tg_bot_id tg_bot_token tg_botname irc_botname nick

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getMe]

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		die "Telegram-API: bad result from getMe method: [jsonGetValue $result "" "description"]"
	}

	set tg_botname [jsonGetValue $result "result" "username"]
	set irc_botname "$nick"
}



# ---------------------------------------------------------------------------- #
# Procedures for sending data to the Telegram servers                          #
# ---------------------------------------------------------------------------- #
# Changes the bot's status in Telegram                                         #
# ---------------------------------------------------------------------------- #
proc tg_sendChatAction {chat_id action} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/sendChatAction -d chat_id=$chat_id -d action=$action]
	return result
}

# ---------------------------------------------------------------------------- #
# Sends a message to a chat group in Telegram                                  #
# ---------------------------------------------------------------------------- #
proc tg_sendMessage {chat_id parse_mode message} {
	global tg_bot_id tg_bot_token tg_web_page_preview

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/sendMessage -d disable_web_page_preview=$tg_web_page_preview -d chat_id=$chat_id -d parse_mode=$parse_mode -d text=$message]
	return result
}

# ---------------------------------------------------------------------------- #
# Sends a message to a chat group in Telegram                                  #
# ---------------------------------------------------------------------------- #
proc tg_sendReplyToMessage {chat_id msg_id parse_mode message} {
	global tg_bot_id tg_bot_token tg_web_page_preview

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/sendMessage -d disable_web_page_preview=$tg_web_page_preview -d chat_id=$chat_id -d parse_mode=$parse_mode -d reply_to_message_id=$msg_id -d text=$message]
	return result
}

# ---------------------------------------------------------------------------- #
# Sends a photo to a chat group in Telegram                                    #
# ---------------------------------------------------------------------------- #
proc tg_sendPhoto {chat_id msg_id photo caption} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/sendPhoto -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d photo=$photo -d caption=$caption]
	return result
}

# ---------------------------------------------------------------------------- #
# Kicks an user from a chat group in Telegram                                  #
# ---------------------------------------------------------------------------- #
proc tg_kickChatMember {chat_id user_id} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/kickChatMember -d chat_id=$chat_id -d user_id=$user_id]
	return result
}

# ---------------------------------------------------------------------------- #
# Get up to date information about the chat group in Telegram                  #
# ---------------------------------------------------------------------------- #
proc tg_getChat {chat_id} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getChat -d chat_id=$chat_id]
	return result
}

# ---------------------------------------------------------------------------- #
# Get a list of administrators in a chat group in Telegram                     #
# ---------------------------------------------------------------------------- #
proc tg_getChatAdministrators {chat_id} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getChatAdministrators -d chat_id=$chat_id]
	return result
}

# ---------------------------------------------------------------------------- #
# Get the number of members in a chat group in Telegram                        #
# ---------------------------------------------------------------------------- #
proc tg_getChatMembersCount {chat_id} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getChatMembersCount -d chat_id=$chat_id]
	return result
}

# ---------------------------------------------------------------------------- #
# Get information about a member of a chat group in Telegram                   #
# ---------------------------------------------------------------------------- #
proc tg_getChatMember {chat_id user_id} {
	global tg_bot_id tg_bot_token

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getChatMember -d chat_id=$chat_id -d user_id=$user_id]
	return result
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
			tg_sendMessage $chat_id "html" [format $MSG_IRC_MSGSENT "$nick" "$msg"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Let the Telegram group(s) know that someone joined an IRC channel            #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickJoined {nick uhost handle channel} {
	global irc_botname
	global tg_channels MSG_IRC_NICKJOINED

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {$nick ne "$irc_botname"} {
				tg_sendMessage $chat_id "html" [format $MSG_IRC_NICKJOINED "$nick" "irc.tweakers.net/$channel" "$channel"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Let the Telegram group(s) know that someone has left an IRC channel          #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickLeft {nick uhost handle channel message} {
	global tg_channels MSG_IRC_NICKLEFT

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			tg_sendMessage $chat_id "html" [format $MSG_IRC_NICKLEFT "$nick" "irc.tweakers.net/$channel" "$channel" "$message"]
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
			tg_sendMessage $chat_id "html" [format $MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
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
			tg_sendMessage $chat_id "html" [format $MSG_IRC_NICKCHANGE "$nick" "$newnick"]
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that the topic of an IRC channel has changed    #
# ---------------------------------------------------------------------------- #
proc irc2tg_topicChange {nick uhost handle channel topic} {
	global tg_channels MSG_IRC_TOPICCHANGE

	foreach {chat_id tg_channel} [array get tg_channels] {
		if {$channel eq $tg_channel} {
			if {$nick ne "*"} {
				tg_sendMessage $chat_id "html" [format $MSG_IRC_TOPICCHANGE "$nick" "irc.tweakers.net/$channel" "$channel" "$topic"]
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
			tg_sendMessage $chat_id "html" [format $MSG_IRC_KICK "$nick" "$target" "$channel" "$reason"]
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
	global tg_bot_id tg_bot_token tg_update_id tg_poll_freq tg_channels utftable irc_botname
	global MSG_TG_MSGSENT MSG_TG_AUDIOSENT MSG_TG_PHOTOSENT MSG_TG_DOCSENT MSG_TG_STICKERSENT MSG_TG_VIDEOSENT MSG_TG_VOICESENT MSG_TG_CONTACTSENT MSG_TG_LOCATIONSENT MSG_TC_VENUESENT MSG_TG_USERADD MSG_TG_USERLEFT MSG_TG_CHATTITLE MSG_TG_PICCHANGE MSG_TG_PICDELETE MSG_TG_UNIMPL

	set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$tg_bot_id:$tg_bot_token/getUpdates?offset=$tg_update_id]

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		putlog "Telegram-API: bad result from getUpdates method: [jsonGetValue $result "" "description"]"
	}

	set recordstart [string first "\{\"update_id\":" $result]
	set idstart $recordstart

	while {$recordstart != -1} {
		set recordend [string first "\{\"update_id\":" $result $recordstart+13]
		if {$recordend == -1} {
			set record [string range $result $recordstart end]
		} else {
			set record [string range $result $recordstart $recordend]
		}

		switch [jsonGetValue $record "chat" "type"] {
			# Check if this record is a private chat record...
			"private" {
				if {[jsonHasKey $record "text"]} {
					# Bug: the object should really be "message" and not ""
					set txt [remove_slashes [utf2ascii [jsonGetValue $record "" "text"]]]
					set msgid [jsonGetValue $record "message" "message_id"]
					set fromid [jsonGetValue $record "from" "id"]

					tg2irc_privateCommands "$fromid" "$msgid" "$txt"
				}
			}

			# Check if this record is a group chat record...
			"group" {
				set chatid [jsonGetValue $record "chat" "id"]
				set name [concat [jsonGetValue $record "from" "first_name"] [jsonGetValue $record "from" "last_name"]]
				
				#
				if {[jsonHasKey $record "text"]} {
					# Bug: the object should really be "message" and not ""
					set txt [remove_slashes [utf2ascii [jsonGetValue $record "" "text"]]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_MSGSENT "[utf2ascii $name]" "$txt"]
							if {[string index $txt 0] eq "/"} {
								set msgid [jsonGetValue $record "message" "message_id"]
								tg2irc_botCommands "$tg_chat_id" "$msgid" "$irc_channel" "$txt"
							}
						}
					}
				}

				# Check if audio has been sent to the Telegram group
				if {[jsonHasKey $record "audio"]} {
					set tg_file_id [jsonGetValue $record "audio" "file_id"]
					set tg_performer [jsonGetValue $record "audio" "performer"]
					set tg_title [jsonGetValue $record "audio" "title"]
					set tg_duration [jsonGetValue $record "audio" "duration"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_AUDIOSENT "[utf2ascii $name]" "$tg_performer" "$tg_title" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a document has been sent to the Telegram group
				if {[jsonHasKey $record "document"]} {
					set tg_file_id [jsonGetValue $record "document" "file_id"]
					set tg_file_name [jsonGetValue $record "document" "file_name"]
					set tg_file_size [jsonGetValue $record "document" "file_size"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_DOCSENT "[utf2ascii $name]" "$tg_file_name" "$tg_file_size" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[jsonHasKey $record "photo"]} {
					set tg_file_id [jsonGetValue $record "" "file_id"]
					if {[jsonHasKey $record "caption"]} {
						# Bug: the object should really be "photo" and not ""
						set caption " ([utf2ascii [remove_slashes [jsonGetValue $record "" "caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PHOTOSENT "[utf2ascii $name]" "$caption" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a sticker has been sent to the Telegram group
				if {[jsonHasKey $record "sticker"]} {
					set emoji [jsonGetValue $record "thumb" "file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_STICKERSENT "[utf2ascii $name]" "[sticker2ascii $emoji]"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[jsonHasKey $record "video"]} {
					set tg_file_id [jsonGetValue $record "video" "file_id"]
					set tg_duration [jsonGetValue $record "video" "duration"]
					if {[jsonHasKey $record "caption"]} {
						# Bug: the object should really be "video" and not ""
						set caption " ([utf2ascii [remove_slashes [jsonGetValue $record "" "caption"]]])"
					} else {
						set caption ""
					}

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_VIDEOSENT "[utf2ascii $name]" "$caption" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a voice object has been sent to the Telegram group
				if {[jsonHasKey $record "voice"]} {
					set tg_file_id [jsonGetValue $record "voice" "file_id"]
					set tg_duration [jsonGetValue $record "voice" "duration"]
					set tg_file_size [jsonGetValue $record "document" "file_size"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_VOICESENT "[utf2ascii $name]" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_fie_size" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a contact has been sent to the Telegram group
				if {[jsonHasKey $record "contact"]} {
					set tg_phone_number [jsonGetValue $record "contact" "phone_number"]
					set tg_first_name [jsonGetValue $record "contact" "first_name"]
					set tg_last_name [jsonGetValue $record "contact" "last_name"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_CONTACTSENT "[utf2ascii $name]" "$tg_phone_number" "$tg_first_name" "$tg_last_name"]
						}
					}
				}

				# Check if a location has been sent to the Telegram group
				if {[jsonHasKey $record "location"]} {
					set tg_longitude [jsonGetValue $record "location" "longitude"]
					set tg_latitude [jsonGetValue $record "location" "latitude"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_LOCATIONSENT "[utf2ascii $name]" "$tg_longitude" "$tg_latitude"]
						}
					}
				}

				# Check if a venue has been sent to the Telegram group
				if {[jsonHasKey $record "venue"]} {
					set tg_location [jsonGetValue $record "venue" "location"]
					set tg_title [jsonGetValue $record "venue" "title"]
					set tg_address [jsonGetValue $record "venue" "address"]
					set tg_foursquare_id [jsonGetValue $record "venue" "foursquare_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_VENUESENT "[utf2ascii $name]" "$tg_location" "$tg_title" "$tg_address" "$tg_foursquare_id"]
						}
					}
				}

				# Check if someone has been added to the Telegram group
				if {[jsonHasKey $record "new_chat_member"]} {
					set new_chat_member [concat [jsonGetValue $record "new_chat_member" "first_name"] [jsonGetValue $record "new_chat_member" "last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_USERADD "[utf2ascii $name]" "[utf2ascii $new_chat_member]"]
						}
					}
				}

				# Check if someone has been removed from the Telegram group
				if {[jsonHasKey $record "left_chat_member"]} {
					set left_chat_member [concat [jsonGetValue $record "left_chat_member" "first_name"] [jsonGetValue $record "left_chat_member" "last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_USERLEFT "[utf2ascii $name]" "[utf2ascii $left_chat_member]"]
						}
					}
				}

				# Check if the title of the Telegram group chat has changed
				if {[jsonHasKey $record "new_chat_title"]} {
					# Bug: the object should really be "message" and not ""
					set chat_title [jsonGetValue $record "" "new_chat_title"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_CHATTITLE "[utf2ascii $name]" "[utf2ascii $chat_title]"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has changed
				if {[jsonHasKey $record "new_chat_photo"]} {
					# Bug: the object should really be "message" and not ""
					set tg_file_id [jsonGetValue $record "" "file_id"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PICCHANGE "[utf2ascii $name]" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has been deleted
				if {[jsonHasKey $record "delete_chat_photo"]} {
					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_PICDELETE "[utf2ascii $name]"
						}
					}
				}
			}

			# Check if this record is a supergroup record
			"supergroup" {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Supergroup message received ($record)"
					}
				}
			}

			# Check if this record is a channel record
			"channel" {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Channel message received ($record)"
					}
				}
			}
		}

		set recordstart $recordend
	}

	if {$idstart != -1} {
		set idend [string first "," $result $idstart+13]
		set tg_update_id [string range $result $idstart+13 $idend-1]
		incr tg_update_id
	}

	utimer $tg_poll_freq tg2irc_pollTelegram
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc tg2irc_botCommands {chat_id msgid channel message} {
	global tg_botname irc_botname
	global MSG_BOT_HELP MSG_BOT_TG_TOPIC MSG_BOT_IRC_TOPIC MSG_BOT_HELP_IRCUSER MSG_BOT_IRCUSER MSG_BOT_TG_UNKNOWNUSER MSG_BOT_IRCUSERS TG_BOT_UNKNOWNCMD

	set message [string trim [string map -nocase {"@$tg_botname" ""} $message]]
	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	switch $command {
		"help" {
			tg_sendChatAction $chat_id "typing"

			set response "[format $MSG_BOT_HELP "$irc_botname"]"
			tg_sendReplyToMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"irctopic" {
			tg_sendChatAction $chat_id "typing"

			set response "[format $MSG_BOT_TG_TOPIC "irc.tweakers.net/$channel" "$channel" "[topic $channel]"]"
			tg_sendReplyToMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircuser" {
			tg_sendChatAction $chat_id "typing"
			set handle [string trim [string range $message $parameter_start end]]

			if {$handle != ""} {
				if {[onchan $handle $channel]} {
					set online_since [getchanjoin $handle $channel]
					set response "[format $MSG_BOT_IRCUSER $handle $online_since irc.tweakers.net/$channel $channel [getchanhost $handle $channel]]"
				} else {
					set response "[format $MSG_BOT_TG_UNKNOWNUSER $handle irc.tweakers.net/$channel $channel]"
				}
			} else {
				set response $MSG_BOT_HELP_IRCUSER
			}
			tg_sendReplyToMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircusers" {
			tg_sendChatAction $chat_id "typing"

			set response "[format $MSG_BOT_IRCUSERS irc.tweakers.net/$channel $channel [chanlist $channel]]"
			tg_sendReplyToMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"get" {
			imagesearch_getImage $chat_id $msgid $channel $message $parameter_start
		}

		default {
			set response "[format $TG_BOT_UNKNOWNCMD "$irc_botname"]"
			tg_sendChatAction $chat_id "typing"
			tg_sendReplyToMessage $chat_id $msgid "markdown" "$TG_BOT_UNKNOWNCMD"
			putchan $channel "$response"
		}
	}
}

# ---------------------------------------------------------------------------- #
# Respond to private commands send by Telegram users                           #
# ---------------------------------------------------------------------------- #
proc tg2irc_privateCommands {from_id msgid message} {
	global tg_owner_id
	global MSG_BOT_CONNECTED MSG_BOT_DISCONNECTED MSG_BOT_UNAUTHORIZED MSG_BOT_UNKNOWNCMD

	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	tg_sendChatAction $from_id "typing"

	switch $command {
		"notifications" {
		}

		"addadmin" {
		}

		"removeadmin" {
		}

		"connect" {
			if {$from_id == $tg_owner_id} {
				tg_sendReplyToMessage $from_id $msgid "markdown" "[format $MSG_BOT_CONNECTED "-12345" "Lamer test" "#lamer-test"]"
			} else {
				tg_sendReplyToMessage $from_id $msgid "markdown" "$MSG_BOT_UNAUTHORIZED"
			}
		}

		"disconnect" {
			if {$from_id == $tg_owner_id} {
				tg_sendReplyToMessage $from_id $msgid "markdown" "[format $MSG_BOT_DISCONNECTED "-12345" "Lamer test" "#lamer-test"]"
			} else {
				tg_sendReplyToMessage $from_id $msgid "markdown" "$MSG_BOT_UNAUTHORIZED"
			}
		}

		"binds" {
			if {$from_id == $tg_owner_id} {
				tg_sendReplyToMessage $from_id $msgid "markdown" "[binds]"
			} else {
				tg_sendReplyToMessage $from_id $msgid "markdown" "$MSG_BOT_UNAUTHORIZED"
			}
		}

		default {
			tg_sendReplyToMessage $from_id $msgid "markdown" "$MSG_BOT_UNKNOWNCMD"
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
	return $txt
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
# Check if a JSON key is present                                               #
# ---------------------------------------------------------------------------- #
proc jsonHasKey {record key} {
	if {[string first $key $record] != -1} {
		return 1
	} else {
		return 0
	}
}

# ---------------------------------------------------------------------------- #
# Return the value of a JSON key                                               #
# ---------------------------------------------------------------------------- #
proc jsonGetValue {record object key} {
	set length [string length $key]
	set objectstart [string first "\"$object\":\{" $record]
	# Bug: this is a quick fix because this procedure doesn't iterate through all the objects correctly yet
	if {$object eq ""} {
		set objectend [string length $record]
	} else {
		set objectend [string first "\}" $record $objectstart]
	}

	set keystart [string first "\"$key\":" $record $objectstart]
	if {$keystart != -1} {
		if {$keystart < $objectend} {
			if {[string index $record [expr $keystart+$length+3]] eq "\""} {
				set end [string first "\"" $record [expr $keystart+$length+5]]
				return [string range $record [expr $keystart+$length+4] $end-1]
			} else {
				set end [string first "," $record [expr $keystart+$length+3]]
				return [string range $record [expr $keystart+$length+3] $end-1]
			}
		}
	}
	return ""
}



# ---------------------------------------------------------------------------- #
# Start of main code                                                           #
# ---------------------------------------------------------------------------- #
# Start bot by loading Telegram modules, bind actions and do a Telegram poll   #
# ---------------------------------------------------------------------------- #

# Load some stuff
source "utftable.tcl"
source "Telegram-API.$language.tcl"

# Load modules
source "ImageSearch.tcl"


bind pubm - * irc2tg_sendMessage
bind join - * irc2tg_nickJoined
bind part - * irc2tg_nickLeft
bind sign - * irc2tg_nickLeft
bind ctcp - "ACTION" irc2tg_nickAction
bind nick - * irc2tg_nickChange
bind topc - * irc2tg_topicChange
bind kick - * irc2tg_nickKicked

initialize

tg2irc_pollTelegram

putlog "Script loaded: conf/scripts/Telegram-API/Telegram-API.tcl ($tg_botname)"
