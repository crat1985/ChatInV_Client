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
	app.socket.write_string("$prefix${app.pseudo_text.len:02}${app.pseudo_text}${password_hash.len:02}$password_hash") or {
		ui.message_box(err.msg())
		return
	}
	mut data := []u8{len: 1024}
	length := app.socket.read(mut data) or {
		ui.message_box(err.msg())
		return
	}
	data = data[..length]

	println(data[0].ascii_str())

	match data[0].ascii_str() {
		'1' {
			data = data[1..]
			ui.message_box(data.bytestr())
		}
		'0' {
			data = data[1..]
			ui.message_box("Success : ${data.bytestr()}")
			spawn app.listen_for_messages()

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
}