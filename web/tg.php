<?php
$bot_id		= '123456789';
$bot_token	= 'AABCD-EFGhIjKlMnOpQrStUvWxYz';
$max_file_size	= 20480000;

$file_id_min_length	= 30;
$file_id_max_length	= 58;
$logfile		= 'tg.php.log';
$logfileEnabled		= true;



# Prep the logfile
writeLogfile(strftime('%c', $_SERVER['REQUEST_TIME']) . ' ' . $_SERVER['REMOTE_ADDR'] . ':' . $_SERVER['REMOTE_PORT'] . ' - Requested file_id ' . $_GET['file_id']);

# Get the file_id parameter
$file_id = filter_input(INPUT_GET, 'file_id', FILTER_SANITIZE_STRING, FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH | FILTER_FLAG_STRIP_BACKTICK | FILTER_FLAG_EMPTY_STRING_NULL);
$file_id_length = strlen($file_id);

# Do some sanity checks for the file_id parameter
if (($file_id_length < $file_id_min_length) || ($file_id_length > $file_id_max_length)) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
	writeLogfile(" - FAILED file_id length ( bytes)\n");
	die ('0x00000001');
}
if (!ctype_print($file_id)) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
	writeLogfile(' - FAILED file_id ctype_print\n');
	die ('0x00000002');
}
if (preg_match("/[^A-Za-z0-9\-_]/", $file_id)) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
	writeLogfile(' - FAILED file_id preg_match\n');
	die ('0x00000003');
}

# Get the link to the attachment
try {
	$content = file_get_contents('https://api.telegram.org/bot' . $bot_id . ':' . $bot_token . '/getFile?file_id=' . $file_id, false, NULL, 0, $max_file_size);

	if ($content === false) {
		header ('HTTP/1.0 504 Gateway Time-out');
		header ('Content-Type: text/plain');
		writeLogfile(' - FAILED at getLink1\n');
		die ('0x0000001A');
	}
} catch (Exception $e) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
//	var_dump ($e);
	writeLogfile(' - FAILED at getLink2 ' . $e->getMessage() . '\n');
	die ('0x0000001B');
}

# Translate the JSON response from the Telegram server
$json = json_decode(utf8_encode($content), true);

# Do some sanity checking
if ($json['result']['file_size'] > $max_file_size) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
	writeLogfile(' - FAILED file too big (' . $json['result']['file_size'] . ' bytes)\n');
	die ('0x0000001C');
}

# Get the attachment itself from the Telegram server
try {
	$content = file_get_contents('https://api.telegram.org/file/bot' . $bot_id . ':' . $bot_token . '/' . $json['result']['file_path'], false, NULL, 0, $max_file_size);

	if ($content === false) {
		header ('HTTP/1.0 504 Gateway Time-out');
		header ('Content-Type: text/plain');
		writeLogfile(' - FAILED at getAttachment1\n');
		die ('0x0000002A');
	}
} catch (Exception $e) {
	header ('HTTP/1.0 400 Bad Request');
	header ('Content-Type: text/plain');
//	var_dump ($e);
	writeLogfile(' - FAILED at getAttachment2 ' . $e->getMessage() . '\n');
	die ('0x0000002B');
} finally {
	# Prep the appropiate headers
	header('Cache-Control: no-cache, must-revalidate');
	header('Expires: Wed, 21 Oct 2015 07:28:00 GMT');
	header('Content-Length: ' . basename($json['result']['file_size']));
	header('Content-Type: application/octet-stream');
	header('Content-Disposition: attachment; filename="' . basename($json['result']['file_path']) . '"');

	# Make sure the output buffer is empty, and send the attachment
	ob_clean();
	flush();
	print $content;
	writeLogfile('\n');
	exit;
}

function writeLogfile($text) {
	global $logfile, $logfileEnabled;

	if ($logfileEnabled) {
		file_put_contents($logfile, $text, FILE_APPEND | LOCK_EX);
	}
}
?>
