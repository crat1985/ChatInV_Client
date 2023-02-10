module utils

import ui

pub fn (mut app App) send_message(mut it &ui.TextBox) {
	app.socket.write_string(it.text) or {
		eprintln(err)
		exit(-1)
	}
	app.send_message_text_box_placeholder = ""
}

pub fn (mut app App) listen_for_messages() {
	for {
		mut data := []u8{len: 1024}
		app.socket.read(mut data) or {
			eprintln(err)
			break
		}
		msg := data.bytestr().trim_space()
		app.messages_box_text += msg
		print(msg)
		flush_stdout()
	}
	exit(-1)
}