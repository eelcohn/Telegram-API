# ---------------------------------------------------------------------------- #
# Telegram-API Quote module for Eggdrop v20180119                              #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Configuration settings                                                       #
# ---------------------------------------------------------------------------- #
set quote_database		"/var/packages/eggdrop/etc/scripts/Quotes/quote.txt"



# ---------------------------------------------------------------------------- #
# Quote procedures                                                             #
# ---------------------------------------------------------------------------- #
# Get a quote from the quote-database                                          #
# ---------------------------------------------------------------------------- #

proc quotes_getQuote {chat_id msgid channel message parameter_start} {
	global quote_database
	global MSG_QUOTE_NOTEXIST MSG_QUOTE_NOTFOUND

	set quote_id [string trim [string range $message $parameter_start end]]

	set quote_fd [open "$quote_database" r]
	for {set quote_count 0} { ![eof $quote_fd] } {incr quote_count} {
		gets $quote_fd quote_list($quote_count)
	}
	close $quote_fd

	set quote_count [expr $quote_count - 2]
	if {$quote_id==""} { 
		set quote_id [rand [expr $quote_count + 1]]
		set qot_sel $quote_list($quote_id)
#				putquick "PRIVMSG $chan :Quote \002[expr $qot_sel + 1]\002 of \002[expr $quote_count + 1]:\002 $qot_sel"
	} else {
		if {[string is integer $quote_id]} {
			unset quote_list([expr $quote_count + 1])
			if {![info exists quote_list([expr {$quote_id} - 1])]} {
				set qot_sel [format $MSG_QUOTE_NOTEXIST $quote_id]
			} else {
				set qot_sel $quote_list([expr {$quote_id} - 1])
#						putquick "PRIVMSG $channel :Quote \002$quote_id\002 of \002[expr $quote_count + 1]:\002 $qot_sel"
			}
		} else {
			set quote_id [string tolower $quote_id]
			
			set quote_sel_num 0
			for {set i 0} {$i < $quote_count} {incr i} {
				if {[string first $quote_id [string tolower $quote_list($i)]] != -1} {
					set quote_selection($quote_sel_num) $quote_list($i)
					incr quote_sel_num
				}
			}

			if {$quote_sel_num == 0} {
				set qot_sel [format $MSG_QUOTE_NOTFOUND $quote_id]
			} else {
				set qot_sel $quote_selection([set qot_cur [rand $quote_sel_num]])
			}
		}
	}

	::libtelegram::sendMessage $chat_id $msgid "html" "[url_encode $qot_sel]"
	putchan $channel "$qot_sel"
}

# ---------------------------------------------------------------------------- #
# Add a quote to the quote-database                                            #
# ---------------------------------------------------------------------------- #

proc quotes_addQuote {chat_id msgid channel message parameter_start} {
	global quote_database
	global MSG_QUOTE_QUOTEADDED MSG_QUOTE_ADDHELP

	set quote [remove_slashes [utf2ascii [string trim [string range $message $parameter_start end]]]]

	if {$quote ne ""} {
		exec cp "$quote_database" "$quote_database~"
		set quote_fd [open "$quote_database" a+]
		puts $quote_fd $quote
		close $quote_fd

		::libtelegram::sendMessage $chat_id $msgid "html" $MSG_QUOTE_QUOTEADDED
		putchan $channel $MSG_QUOTE_QUOTEADDED
	} else {
		::libtelegram::sendMessage $chat_id $msgid "html" $MSG_QUOTE_ADDHELP
	}
}
