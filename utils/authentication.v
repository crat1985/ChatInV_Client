module utils

import ui
import ui.component as uic
import time
import crypto.sha256
import net

pub fn (mut app App) login_or_register_textbox(_ &ui.TextBox) {
	app.login_or_register(&ui.Button{})
}

pub fn (mut app App) login_or_register(_ &ui.Button) {
	if app.pseudo_is_error || app.password_is_error {
		ui.message_box("Complete all fields !")
		return
	}

	mut is_connected := true
	app.socket.write([]u8{len: 1}) or {
		is_connected = false
	}
	if is_connected {
		confirm := ui.confirm("Do you want to stop all other connections ?")
		if confirm {
			app.socket.close() or { ui.message_box(err.str()) }
		}
	}

	mut addr := app.addr
	if addr.is_blank() { addr = app.addr_placeholder }
	mut port := app.port
	if port.is_blank() { port = app.port_placeholder }

	app.socket = net.dial_tcp("$addr:$port") or {
		ui.message_box(err.msg())
		return
	}

	app.socket.set_read_timeout(time.infinite)

	app.send_credentials()
}

pub fn (mut app App) send_credentials() {
	mut prefix := match app.mode {
		.register {
			"r"
		}
		.login {
			"l"
		}
	}
	password_hash := sha256.hexhash(app.password_text)
	println("${app.pseudo_text.len:02}")
	app.send_string("$prefix${app.pseudo_text.len:02}${app.pseudo_text}${password_hash.len:02}$password_hash") or {
		ui.message_box(err.msg())
		return
	}
	mut all_data := []u8{len: 1024}
	mut length := app.socket.read(mut all_data) or {
		ui.message_box(err.msg())
		return
	}
	all_data = all_data[..length]
	mut data := all_data.bytestr()

	if data.len < 6 {
		eprintln("[LOG] Msg received too short : $data")
		return
	}

	length = data[..5].int()
	data = data[5..]
	if data.len < length {
		eprintln("[LOG] Invalid message, this should never happen, report it to the developer : $data")
		return
	}

	match data[0].ascii_str() {
		'1' {
			ui.message_box(data[1..length])
			return
		}
		'0' {
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

	if data.len == length {
		return
	}
	data = data[..length+1]
	app.display_messages(data)
	spawn app.listen_for_messages()
}