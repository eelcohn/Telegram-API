# ---------------------------------------------------------------------------- #
# Telegram-API Quote module for Eggdrop v20180207                              #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

namespace eval Quotes {}
source "[file join [file dirname [info script]] Quotes.conf]"

# ---------------------------------------------------------------------------- #
# Quote procedures                                                             #
# ---------------------------------------------------------------------------- #
# Get a quote from the quote-database                                          #
# ---------------------------------------------------------------------------- #

proc quotes_getQuote {chat_id msgid channel message parameter_start} {
	global quote_database

	set quote_id [string trim [string range $message $parameter_start end]]

	set quote_fd [open "$::Quotes::quote_database" r]
	for {set quote_count 0} { ![eof $quote_fd] } {incr quote_count} {
		gets $quote_fd quote_list($quote_count)
	}
	close $quote_fd

	set quote_count [expr $quote_count - 1]
	if {$quote_id == ""} { 
		set quote_id [rand $quote_count]
		set qot_sel $quote_list($quote_id)
	} else {
		if {[string is integer $quote_id]} {
			unset quote_list($quote_count)
			unset quote_list([expr $quote_count - 1])
			if {![info exists quote_list([expr {$quote_id} - 1])]} {
				set qot_sel [::msgcat::mc MSG_QUOTE_NOTEXIST $quote_id]
			} else {
				set qot_sel $quote_list([expr {$quote_id} - 1])
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
				set qot_sel [::msgcat::mc MSG_QUOTE_NOTFOUND $quote_id]
			} else {
				set qot_sel $quote_selection([set qot_cur [rand $quote_sel_num]])
			}
		}
	}

	::libtelegram::sendMessage $chat_id $msgid "html" "[url_encode $qot_sel]"
	putchan $channel "[::libunicode::utf82ascii $qot_sel]"
}

# ---------------------------------------------------------------------------- #
# Add a quote to the quote-database                                            #
# ---------------------------------------------------------------------------- #

proc quotes_addQuote {chat_id msgid channel message parameter_start} {
	global quote_database

	set quote [remove_slashes [string trim [string range $message $parameter_start end]]]

	if {$quote ne ""} {
		file copy -force "$::Quotes::quote_database" "$::Quotes::quote_database~"
		set quote_fd [open "$::Quotes::quote_database" a+]
		puts $quote_fd "$quote"
		close $quote_fd

		::libtelegram::sendMessage $chat_id $msgid "html" "[::msgcat::mc MSG_QUOTE_QUOTEADDED]"
		putchan $channel "[::msgcat::mc MSG_QUOTE_QUOTEADDED]"
	} else {
		::libtelegram::sendMessage $chat_id $msgid "html" "[::msgcat::mc MSG_QUOTE_ADDHELP]"
	}
}

add_public_command quote quotes_getQuote "(keyword/id): Show a quote from the legendary quotes-database."
add_public_command addquote quotes_addQuote "<quote>: Adds a quote to the legendary quote database."
