module utils

import ui

pub fn (mut app App) send_message(mut it &ui.TextBox) {
	app.send_encrypted_string(it.text.bytes().bytestr()) or {
		eprintln(err)
		exit(-1)
	}
	app.send_message_textbox_text = ""
	app.messages_box.tv.do_logview()
}

pub fn (mut app App) send_encrypted_string(data string) !int {
	return app.socket.write(app.encrypt_string("${data.len:05}$data"))
}

pub fn (mut app App) listen_for_messages() {
	for {
		mut data := []u8{len: 1024}
		length := app.socket.read(mut data) or {
			panic(err)
		}
		app.display_messages(app.decrypt_string(data[..length]) or {
			eprint("Couldn't decrypt message : $err")
			continue
		})
		app.messages_box.tv.do_logview()
	}
	exit(-1)
}

pub fn (mut app App) display_messages(message string) {
	mut msg := message
	for {
		if msg.len < 6 {
			eprintln("[LOG] Msg received too short : $msg")
			break
		}
		length := msg[..5].int()
		msg = msg[5..]
		if msg.len < length {
			eprintln("[LOG] Invalid message : $msg")
			break
		}
		msg_temp := msg[..length]
		if msg_temp.is_blank() {
			msg = msg[length..]
			continue
		}
		app.messages_box_text += "$msg_temp\n"
		println(msg_temp)
		if msg.len == length {
			break
		}
		msg = msg[length..]
	}
}