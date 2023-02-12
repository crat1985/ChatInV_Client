module utils

import ui

pub fn (mut app App) send_message(mut it &ui.TextBox) {
	app.send_string(it.text.str()) or {
		eprintln(err)
		exit(-1)
	}
	app.send_message_textbox_text = ""
	app.messages_box.tv.do_logview()
}

pub fn (mut app App) send_string(data string) !int {
	return app.socket.write_string("${data.len}$data")
}

pub fn (mut app App) listen_for_messages() {
	for {
		mut data := []u8{len: 1024}
		app.socket.read(mut data) or {
			eprintln(err)
			break
		}
		mut msg := data.bytestr()

		app.display_messages(msg)
	}
	exit(-1)
}

pub fn (mut app App) display_messages(message string) {
	mut msg := message
	for {
		if msg.len < 6 {
			eprintln("[LOG] Msg received too short : $msg")
			continue
		}
		length := msg[..5].int()
		msg = msg[5..]
		if msg.len < length {
			eprintln("[LOG] Invalid message : $msg")
			break
		}
		msg = msg[..length]
		app.messages_box_text += "$msg\n"
		println(msg)
		if msg.len == length {
			break
		}
		msg = msg[length..]
	}
}