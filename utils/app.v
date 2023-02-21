module utils

import net
import ui
import libsodium

[heap]
pub struct App {
	pub mut:
	private_key libsodium.PrivateKey
	box libsodium.Box
	//login win
	window &ui.Window
	username_textbox &ui.TextBox
	pseudo_text string
	pseudo_is_error bool
	password_text string
	password_is_error bool
	socket &net.TcpConn
	addr string
	addr_placeholder string
	port string
	port_placeholder string

	//chat win
	messages_box &ui.TextBox
	messages_box_text string
	send_message_textbox &ui.TextBox
	send_message_textbox_text string

	mode Mode
	confirm_password_text string
	confirm_password_is_error bool
}

pub enum Mode {
	login
	register
}