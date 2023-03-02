module main

import net
import ui
import gx
import utils
import libsodium

fn main() {
	mut app := &utils.App{
		private_key: libsodium.new_private_key()
		box: libsodium.Box{}
		window: 0
		pseudo_text: ''
		pseudo_is_error: true
		password_text: ''
		password_is_error: true
		socket: &net.TcpConn{}
		addr: ''
		addr_placeholder: 'localhost'
		port: ''
		port_placeholder: '8888'
		send_message_textbox: 0
		send_message_textbox_text: ''
		messages_box: 0
		messages_box_text: ''
		mode: utils.Mode.login
		username_textbox: 0
		confirm_password_text: ''
		confirm_password_is_error: true
	}

	app.window = ui.window(
		title: 'Login'
		bg_color: gx.color_from_string('black')
		on_init: utils.init
		width: 300
		height: 400
		children: [
			ui.column(
				id: 'main_col'
				margin_: 16
				heights: ui.stretch
				children: [
					app.build_login_window(),
					app.build_chat_app(),
				]
			),
		]
	)
	ui.run(app.window)
}
