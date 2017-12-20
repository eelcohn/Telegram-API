# ---------------------------------------------------------------------------- #
# Telegram-API module v20171219 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

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
	global tg_botname irc_botname nick

	set result [::libtelegram::getMe]

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		die "Telegram-API: bad result from getMe method: [jsonGetValue $result "" "description"]"
	}

	set tg_botname [jsonGetValue $result "result" "username"]
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
			libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_MSGSENT "$nick" "[url_encode $msg]"]
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
				libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKJOINED "$nick" "$serveraddress/$channel" "$channel"]
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
				libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKLEFT "$nick" "$serveraddress/$channel" "$channel" "$message"]
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
			libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
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
			libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_NICKCHANGE "$nick" "$newnick"]
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
				libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_TOPICCHANGE "$nick" "$serveraddress/$channel" "$channel" "$topic"]
				libtelegram::setChatTitle $chat_id $topic
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
			libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_KICK "$nick" "$target" "$channel" "$reason"]
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
			libtelegram::sendMessage $chat_id "" "html" [format $MSG_IRC_MODECHANGE "$nick" "$channel" "$mode"]
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

	set result [libtelegram::getUpdates $tg_update_id]

	if {$result == -1} {
		# Dont go into the parsing process but plan the next polling
		utimer $tg_poll_freq tg2irc_pollTelegram
 		return -1
	}

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		# Dont go into the parsing process but plan the next polling
		putlog "Telegram-API: bad result from getUpdates method: [jsonGetValue $result "" "description"]"
		utimer $tg_poll_freq tg2irc_pollTelegram
		return -1
	}

	set recordstart [string first "\{\"update_id\":" $result]
	
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

			# Check if this record is a group or supergroup chat record...
			"supergroup" -
			"group" {
				set chatid [jsonGetValue $record "chat" "id"]
				set name [utf2ascii [jsonGetValue $record "from" "username"]]
				if {$name == "" } {
					set name [utf2ascii [concat [jsonGetValue $record "from" "first_name"] [jsonGetValue $record "from" "last_name"]]]
				}
				if {$colorize_nicknames == "true"} {
					set name "\003[getColorFromString $name]$name\003"
				}

				# Check if a text message has been sent to the Telegram group
				if {[jsonHasKey $record "text"]} {
					# Bug: the object should really be "message" and not ""
					set txt [utf2ascii [jsonGetValue $record "" "text"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							foreach line [split [string map {\\n \n} $txt] "\n"] {
								putchan $irc_channel [format $MSG_TG_MSGSENT "$name" "[remove_slashes $line]"]
								if {[string match -nocase "*http://?*" $line] || [string match -nocase "*https://?*" $line] || [string match -nocase "*www.?*" $line]} {
									putchan $irc_channel [getWebsiteTitle $line]
								}
							}
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
				if {[jsonHasKey $record "document"]} {
					set tg_file_id [jsonGetValue $record "document" "file_id"]
					set tg_file_name [jsonGetValue $record "document" "file_name"]
					set tg_file_size [jsonGetValue $record "document" "file_size"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_DOCSENT " $name" "$tg_file_name" "$tg_file_size" "$irc_botname" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[jsonHasKey $record "photo"]} {
					set tg_file_id [jsonGetValue $record "" "file_id"]
					if {[jsonHasKey $record "caption"]} {
						# Bug: the object should really be "photo" and not ""
						set caption " ([remove_slashes [utf2ascii [jsonGetValue $record "" "caption"]]])"
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
				if {[jsonHasKey $record "sticker"]} {
					set emoji [jsonGetValue $record "sticker" "emoji"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_STICKERSENT "$name" "[sticker2ascii $emoji]"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[jsonHasKey $record "video"]} {
					set tg_file_id [jsonGetValue $record "video" "file_id"]
					set tg_duration [jsonGetValue $record "video" "duration"]
					if {$tg_duration eq ""} {
						set tg_duration "0"
					}

					if {[jsonHasKey $record "caption"]} {
						# Bug: the object should really be "video" and not ""
						set caption " ([utf2ascii [remove_slashes [jsonGetValue $record "" "caption"]]])"
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
				if {[jsonHasKey $record "voice"]} {
					set tg_file_id [jsonGetValue $record "voice" "file_id"]
					set tg_duration [jsonGetValue $record "voice" "duration"]
					set tg_file_size [jsonGetValue $record "document" "file_size"]
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
				if {[jsonHasKey $record "contact"]} {
					set tg_phone_number [jsonGetValue $record "contact" "phone_number"]
					set tg_first_name [jsonGetValue $record "contact" "first_name"]
					set tg_last_name [jsonGetValue $record "contact" "last_name"]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [format $MSG_TG_CONTACTSENT "$name" "$tg_phone_number" "$tg_first_name" "$tg_last_name"]
						}
					}
				}

				# Check if a location has been sent to the Telegram group
				if {[jsonHasKey $record "location"]} {
					# Check if a venue has been sent to the Telegram group
					if {[jsonHasKey $record "venue"]} {
						set tg_location [jsonGetValue $record "venue" "location"]
						set tg_title [jsonGetValue $record "venue" "title"]
						set tg_address [jsonGetValue $record "venue" "address"]
						set tg_foursquare_id [jsonGetValue $record "venue" "foursquare_id"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [format $MSG_TG_VENUESENT "$name" "$tg_location" "$tg_title" "$tg_address" "$tg_foursquare_id"]
							}
						}
					} else {
					# Not a venue, so it must be a location
						set tg_longitude [jsonGetValue $record "location" "longitude"]
						set tg_latitude [jsonGetValue $record "location" "latitude"]

						foreach {tg_chat_id irc_channel} [array get tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [format $MSG_TG_LOCATIONSENT "$name" "$tg_longitude" "$tg_latitude"]
							}
						}
					}
				}


				# Check if someone has been added to the Telegram group
				if {[jsonHasKey $record "new_chat_member"]} {
					set new_chat_member [concat [jsonGetValue $record "new_chat_member" "first_name"] [jsonGetValue $record "new_chat_member" "last_name"]]

					foreach {tg_chat_id irc_channel} [array get tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $left_chat_member} {
								putchan $irc_channel [format $MSG_TG_USERJOINED "[utf2ascii $name]"]
							} else {
								putchan $irc_channel [format $MSG_TG_USERADD "[utf2ascii $name]" "[utf2ascii $new_chat_member]"]
							}
						}
					}
				}

				# Check if someone has been removed from the Telegram group
				if {[jsonHasKey $record "left_chat_member"]} {
					set left_chat_member [concat [jsonGetValue $record "left_chat_member" "first_name"] [jsonGetValue $record "left_chat_member" "last_name"]]

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

			# Check if this record is a channel record
			"channel" {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Channel message received ($record)"
					}
				}
			}

			# Handle any unknown messages
			default {
				foreach {tg_chat_id irc_channel} [array get tg_channels] {
					if {$chatid eq $tg_chat_id} {
						putchan $irc_channel [format $MSG_TG_UNIMPLEMENTED "Unknown message received ($record)"
					}
				}
			}
		}

		set recordstart $recordend
	}

	# Set the update_id for the next poll
	set recordend [string last "\{\"update_id\":" $result]
	if {$recordend != -1} {
		set idend [string first "," $result $recordend+13]
		set tg_update_id [string range $result $recordend+13 $idend-1]
		incr tg_update_id
	}

	# ...and set a timer so it triggers the next poll
	utimer $tg_poll_freq tg2irc_pollTelegram
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc tg2irc_botCommands {chat_id msgid channel message} {
	global serveraddress tg_botname irc_botname
	global MSG_BOT_HELP MSG_BOT_TG_TOPIC MSG_BOT_IRC_TOPIC MSG_BOT_HELP_IRCUSER MSG_BOT_IRCUSER MSG_BOT_TG_UNKNOWNUSER MSG_BOT_IRCUSERS MSG_BOT_UNKNOWNCMD

	set message [string trim [string map -nocase {"@$tg_botname" ""} $message]]
	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	libtelegram::sendChatAction $chat_id "typing"

	switch $command {
		"help" {
			set response "[format $MSG_BOT_HELP "$irc_botname"]"
			sbtelegram::endMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"irctopic" {
			set response "[format $MSG_BOT_TG_TOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
			libtelegram::sendMessage $chat_id $msgid "html" "$response"
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
			libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircusers" {
			set response "[format $MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[chanlist $channel]"]"
			libtelegram::sendMessage $chat_id $msgid "html" "$response"
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
			libtelegram::sendMessage $chat_id $msgid "markdown" "$MSG_BOT_UNKNOWNCMD"
			putchan $channel "$MSG_BOT_UNKNOWNCMD"
		}
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
#				libtelegram::sendMessage $from_id $msgid "markdown" "[format $MSG_BOT_PASSWORDSET "$tg_botname"]"
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
				libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERLOGIN "$tg_botname" "$irchandle"]\n\n $lastlogin"
			} else {
				# Username/password combo doesn't match
				libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_USERPASSWRONG"
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
				libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERLOGOUT "$irchandle" "$from_id"]"
			} else {
				libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_NOTLOGGEDIN"
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
				libtelegram::sendMessage $from_id $msgid "html" "[format $MSG_BOT_USERINFO "$irchandle" "$from_id" "$tg_lastlogin" "$tg_lastlogout" "$tg_lastuserid" "$tg_created" "$irc_created" "$irc_laston" "irc_hosts" "$irc_info"]"
			} else {
				libtelegram::sendMessage $from_id $msgid "html" "$MSG_BOT_NOTLOGGEDIN"
			}
		}

		"help" {
			libtelegram::sendMessage $from_id $msgid "html" "Available commands are:\n login <username> <password>\n logout\n myinfo\n help\n"
		}

		default {
			libtelegram::sendMessage $from_id $msgid "markdown" "$MSG_BOT_UNKNOWNCMD"
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
				if {$end != -1} {
					return [string range $record [expr $keystart+$length+3] $end-1]
				} else {
					set end [string first "\}" $record [expr $keystart+$length+3]]
					if {$end != -1} {
						return [string trim [string range $record [expr $keystart+$length+3] $end-1]]
					} else {
						return "UNKNOWN"
					}
				}
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

set scriptdir [file dirname [info script]]

source "$scriptdir/Telegram-API-config.tcl"
source "$scriptdir/utftable.tcl"
source "$scriptdir/lang/Telegram-API.$language.tcl"
source "$scriptdir/lib/libtelegram.tcl"

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

