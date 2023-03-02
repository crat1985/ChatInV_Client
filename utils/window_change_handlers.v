module utils

import ui

pub fn (mut app App) pseudo_changed(it &ui.TextBox) {
	app.pseudo_text = it.text
	app.pseudo_is_error = app.pseudo_text.len < 3
}

pub fn (mut app App) password_changed(it &ui.TextBox) {
	app.password_text = it.text
	app.password_is_error = app.password_text.len < 8
}

pub fn (mut app App) confirm_password_changed(it &ui.TextBox) {
	app.confirm_password_text = it.text
	app.confirm_password_is_error = app.password_text != app.confirm_password_text
		&& !app.password_is_error && app.mode == Mode.register
}

fn (mut app App) addr_changed(it &ui.TextBox) {
	app.addr = it.text
}

fn (mut app App) port_changed(it &ui.TextBox) {
	app.port = it.text
}
