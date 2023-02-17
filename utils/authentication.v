module utils

import ui
import ui.component as uic
import time
import crypto.sha256
import net
import libsodium

pub fn (mut app App) login_or_register_textbox(_ &ui.TextBox) { app.login_or_register(&ui.Button{}) }

pub fn (mut app App) login_or_register(_ &ui.Button) {
	if app.pseudo_is_error || app.password_is_error {
		ui.message_box("Complete all fields !")
		return
	}
	if app.confirm_password_is_error && app.mode==Mode.register {
		ui.message_box("Confirm password and password don't match !")
		return
	}
	mut is_connected := true
	app.socket.write([]u8{len: 1}) or {
		is_connected = false
	}
	if is_connected {
		if ui.confirm("Do you want to stop all other connections ?") {
			app.socket.close() or {
				ui.message_box(err.msg())
			}
		}
		return
	}
	addr := if app.addr.is_blank() {
		app.addr_placeholder
	} else {
		app.addr
	}
	port := if app.port.is_blank() {
		app.port_placeholder
	} else {
		app.port
	}

	app.socket = net.dial_tcp("$addr:$port") or {
		ui.message_box(err.msg())
		return
	}
	app.socket.set_read_timeout(time.infinite)

	app.get_public_key()

	app.get_session_key()

	app.send_credentials()
}

pub fn (mut app App) get_public_key() {
	mut public_key := []u8{len: 32}
	app.socket.read(mut public_key) or {
		panic(err)
	}
	println(public_key.hex())
	app.box = libsodium.new_box(app.private_key, public_key)
	app.socket.write(app.private_key.public_key) or {
		panic(err)
	}
}

pub fn (mut app App) get_session_key() {
	mut encrypted_session_key := []u8{len: 1024}
	length := app.socket.read(mut encrypted_session_key) or {
		panic(err)
	}
	encrypted_session_key = encrypted_session_key[..length]
	app.session_key = app.box.decrypt(encrypted_session_key)
}

pub fn (mut app App) send_credentials() {
	prefix := match app.mode {
		.register {
			"r"
		}
		.login {
			"l"
		}
	}
	password_hash := sha256.hexhash(app.password_text)
	//send credentials
	app.send_string("$prefix${app.pseudo_text.len:02}${app.pseudo_text}$password_hash") or {
		ui.message_box(err.msg())
		return
	}
	mut bytes_data := []u8{len: 1024}
	//listen for server's response
	mut length := app.socket.read(mut bytes_data) or {
		ui.message_box(err.msg())
		return
	}
	//remove null bytes
	bytes_data = bytes_data#[..length]
	if bytes_data.len == 0 {
		eprintln("[ERROR] Bad data received !")
		return
	}
	//converting to string
	mut data := bytes_data.bytestr()

	length = data#[..5].int()
	if length == 0 {
		eprintln("[ERROR] Bad length !")
		return
	}
	data = data#[5..]
	if data.len == 0 {
		eprintln("[ERROR] Bad length !")
		return
	}
	if data.len < length {
		eprintln("[ERROR] Invalid message, this should never happen, report it to the developer : `$data`")
		return
	}

	match data[0].ascii_str() {
		'1' {
			//show error message
			ui.message_box(data[1..length])
			return
		}
		'0' {
			//show success message
			ui.message_box("Success : ${data[1..length]}")

			uic.hideable_show(app.window, "hchat")
			uic.hideable_toggle(app.window, "hform")
			app.window.update_layout()
			app.window.set_title("Chat app")
		}
		else {
			ui.message_box("Error while receiving server's response, this should never happens.\nReport it to the developer.")
			return
		}
	}

	spawn app.listen_for_messages()

	if data.len == length {
		return
	}
	//sending end of the message
	app.display_messages(data[length..])
}