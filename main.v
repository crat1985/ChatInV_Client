module main

import net
import ui
import gx
import utils

fn main() {
	mut app := &utils.App{
		window: 0
		pseudo_text: ""
		pseudo_is_error: true
		password_text: ""
		password_is_error: true
		socket: &net.TcpConn{}
		addr: ""
		addr_placeholder: "localhost"
		port: ""
		port_placeholder: "8888"

		send_message_text_box_placeholder: ''
		messages_box_text: ''
	}

	app.window = ui.window(
		title: "Login"
		mode: .resizable
		//resizable: false
		bg_color: gx.color_from_string("black")
		on_init: app.init
		width: 300
		height: 400
		children: [
			ui.column(
				id: "main_col"
				margin_: 0
				heights: ui.stretch
				children: [
					app.build_login_window()
					app.build_chat_app()
				]
			)
		]
	)

	ui.run(app.window)
}
