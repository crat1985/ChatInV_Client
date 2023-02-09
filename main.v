module main

import net
import os
import time
import ui
import gx

[heap]
struct App {
	mut:
	window &ui.Window
	pseudo_text_box &ui.TextBox
	pseudo_text string
	pseudo_is_error bool
	password_text string
	password_is_error bool
	socket &net.TcpConn
	addr string
	port int
}

fn main() {
	mut app := &App{
		window: 0
		pseudo_text_box: 0
		pseudo_text: ""
		pseudo_is_error: true
		password_text: ""
		password_is_error: true
		socket: 0
		addr: ""
		port: 0
	}

	app.window = ui.window(
		title: "Chat in V"
		mode: .resizable
		//resizable: false
		width: 360
		height: 480
		bg_color: gx.color_from_string("black")
		children: [
			ui.column(
				alignment: .center
				margin_: 16
				widths: ui.stretch
				spacing: 16
				children: [
					ui.label(
						text: "Se connecter"
						//text_align: .center
						text_color: gx.rgb(255, 255, 255)
						justify: [0.5, 0.5]
						text_size: 22
					)

					ui.textbox(
						placeholder: "Pseudo"
						on_change: app.pseudo_changed
						is_error: &app.pseudo_is_error
					)

					ui.textbox(
						placeholder: "Mot de passe"
						on_change: app.password_changed
						is_error: &app.password_is_error
						is_password: true
					)

					ui.button(
						text: "Se connecter"
						on_click: app.connect
					)
				]
			)
		]
	)

	ui.run(app.window)
}

fn (mut app App) connect(_ &ui.Button) {
	if app.socket != 0 {
		app.socket.close() or { panic(err) }
	}

	app.socket = net.dial_tcp(app.addr) or { panic(err) }

	app.socket.set_read_timeout(time.infinite)

	spawn app.listen_for_messages()

	for {
		data := os.input("")
		app.socket.write_string(data) or {
			eprintln(err)
			exit(-1)
		}
	}
}

fn (mut app App) listen_for_messages() {
	for {
		mut data := []u8{len: 1024}
		app.socket.read(mut data) or {
			eprintln(err)
			break
		}
		print(data.bytestr())
		flush_stdout()
	}
	exit(-1)
}

fn (mut app App) pseudo_changed(it &ui.TextBox) {
	app.pseudo_text = it.text
	app.pseudo_is_error = app.pseudo_text.len < 3
}

fn (mut app App) password_changed(it &ui.TextBox) {
	app.password_text = it.text
	app.password_is_error = app.password_text.len < 8
}

/*fn get_font_root_path() string {
	$if linux {
		return "/usr/share/fonts/truetype/*"
	}
	$if macos {
		return "/System/Library/Fonts/*"
	}
	$if windows {
		return "C:/windows/fonts"
	}
}

fn get_font_paths() []string {
	font_dir := get_font_root_path()
	return os.glob("$font_dir/*.ttf") or {panic(err)}
}*/
