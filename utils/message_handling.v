module utils

import ui

pub fn (mut app App) send_message(mut it &ui.TextBox) {
	message := it.text.bytes().bytestr()
	if message.is_blank() {
		return
	}
	app.send_encrypted_string(message) or {
		eprintln(err)
		exit(-1)
	}
	app.send_message_textbox_text = ""
	app.messages_box.tv.do_logview()
}

pub fn (mut app App) send_encrypted_string(data string) !int {
	encrypted := app.encrypt_string(data)
	mut all_data := "${encrypted.len:05}".bytes()
	all_data << encrypted
	println(all_data)
	return app.socket.write(all_data)
}

pub fn (mut app App) listen_for_messages() {
	for {
		mut data := []u8{len: 1024}
		length := app.socket.read(mut data) or {
			eprintln(err)
			break
		}
		data = data[..length]
		app.display_messages(mut data)
		app.messages_box.tv.do_logview()
	}
	exit(-1)
}

pub fn (mut app App) display_messages(mut data []u8) {
	for {
		if data.len < 6 {
			eprintln("[LOG] Msg received too short : $data")
			break
		}
		length := data[..5].bytestr().int()
		data = data[5..]
		if data.len < length {
			eprintln("[LOG] Invalid message : ${data.bytestr()}")
			break
		}
		msg_temp := app.decrypt_string(data[..length]) or {
			eprintln(err)
			continue
		}
		if msg_temp.is_blank() {
			data = data[length..]
			continue
		}
		app.messages_box_text += "$msg_temp\n"
		println(msg_temp)
		if data.len == length {
			break
		}
		data = data[length..]
	}
}