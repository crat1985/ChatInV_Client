module utils

import ui
import ui.component as uic
import time
import net
import libsodium

pub fn (mut app App) login_or_register_text_box(_ &ui.TextBox) {
	app.login_or_register(&ui.Button{})
}

pub fn (mut app App) login_or_register(_ &ui.Button) {
	if app.pseudo_is_error || app.password_is_error {
		ui.message_box('Complete all fields !')
		return
	}
	if app.confirm_password_is_error {
		ui.message_box("Confirm password and password don't match !")
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

	app.socket = net.dial_tcp('${addr}:${port}') or {
		ui.message_box(err.msg())
		return
	}
	app.socket.set_read_timeout(time.infinite)

	app.setup_encryption() or { panic(err) }

	app.send_credentials() or { ui.message_box(err.msg()) }
}

pub fn (mut app App) setup_encryption() ! {
	public_key := []u8{len: 32}
	// reading server's public key
	app.socket.read(mut public_key) or { return err }
	// sending client's public key
	app.socket.write(app.private_key.public_key) or { return err }
	// creating new box
	app.box = libsodium.new_box(app.private_key, public_key)
}

pub fn (mut app App) send_credentials() ! {
	prefix := match app.mode {
		.register {
			'r'
		}
		.login {
			'l'
		}
	}
	// send credentials
	app.send_encrypted_string('${prefix}${app.pseudo_text.len:02}${app.pseudo_text}${app.password_text.len:02}${app.password_text}') or {
		return err
	}
	mut server_response := []u8{len: 1024}
	// listen for server's response
	mut length := app.socket.read(mut server_response) or { return err }

	// remove null bytes
	server_response = server_response#[..length]
	if server_response.len == 0 {
		return error('[ERROR] Bad data received !')
	}
	length = server_response[..5].bytestr().int()
	server_response = server_response[5..]

	if server_response.len < length {
		return error('[ERROR] Invalid message, this should never happen, please report it to the developer.')
	}

	// converting to string
	mut decrypted_data := app.decrypt_string(server_response[..length]) or { return err }

	match decrypted_data[0].ascii_str() {
		'1' {
			return error(decrypted_data[1..])
		}
		'0' {
			// show success message
			ui.message_box('Success : ${decrypted_data[1..]}')

			uic.hideable_show(app.window, 'hchat')
			uic.hideable_toggle(app.window, 'hform')
			app.window.update_layout()
			app.window.set_title('Chat app')
		}
		else {
			return error("Error while receiving server's response, this should never happens.\nReport it to the developer.")
		}
	}

	// showing end of the message
	decrypted_data = decrypted_data#[length..]
	if decrypted_data.len > 6 {
		app.display_messages(decrypted_data.bytes())
	}

	spawn app.listen_for_messages()
}
