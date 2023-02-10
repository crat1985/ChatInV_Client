module utils

import net
import ui
import ui.component as uic
import gx

[heap]
pub struct App {
	pub mut:
	window &ui.Window
	pseudo_text string
	pseudo_is_error bool
	password_text string
	password_is_error bool
	socket &net.TcpConn
	addr string
	addr_placeholder string
	port string
	port_placeholder string

	send_message_text_box_placeholder string
	messages_box_text string
}

pub fn (mut app App) init(win &ui.Window) {
	uic.hideable_show(win, "hform")
}

pub fn (mut app App) build_login_window() &ui.Stack {
	return uic.hideable_stack(
		id: "hform",
		layout: ui.column(
			alignment: .center
			margin_: 16
			widths: ui.stretch
			spacing: 16
			children: [
				ui.label(
					text: "Login"
					//text_align: .center
					text_color: gx.rgb(255, 255, 255)
					justify: ui.center
					text_size: 22
				)

				ui.textbox(
					placeholder: "Username"
					on_change: app.pseudo_changed
					is_error: &app.pseudo_is_error
					on_enter: app.connect_textbox
				)

				ui.textbox(
					placeholder: "Password"
					on_change: app.password_changed
					is_error: &app.password_is_error
					is_password: true
					on_enter: app.connect_textbox
				)

				ui.textbox(
					placeholder: app.addr_placeholder
					on_change: app.addr_changed
					on_enter: app.connect_textbox
				)

				ui.textbox(
					placeholder: app.port_placeholder
					on_change: app.port_changed
					is_numeric: true
					on_enter: app.connect_textbox
				)

				ui.button(
					text: "Login"
					on_click: app.connect
				)

			]
		)
	)
}

pub fn (mut app App) build_chat_app() &ui.Stack {
	return uic.hideable_stack(
		id: "hchat",
		layout: ui.column(
			margin_: 16
			heights: [ui.stretch, ui.compact]
			children: [
				ui.textbox(
					text: &app.messages_box_text
					mode: .read_only | .multiline
				)
				ui.textbox(
					text: &app.send_message_text_box_placeholder
					placeholder: "Message"
					on_enter: app.send_message
				)
			]
		)
	)
}