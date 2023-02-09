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
}

fn main() {
	mut app := &App{
		window: 0
		pseudo_text_box: 0
		pseudo_text: ""
		pseudo_is_error: true
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
				children: [
					ui.row(
						alignment: .center
						widths: [ui.fit]
						children: [
							ui.label(
								text: "Se connecter"
								text_align: .center
								text_color: gx.rgb(255, 255, 255)
							)
						]
					)

					ui.textbox(
						placeholder: "Pseudo"
						on_change: app.pseudo_changed
						is_error: &app.pseudo_is_error
					)
				]
			)
		]
	)

	ui.run(app.window)
}

fn connect(addr string) {
	mut socket := net.dial_tcp(addr) or {
		panic(err)
	}

	socket.set_read_timeout(time.infinite)

	spawn listen_for_messages(mut socket)

	for {
		data := os.input("")
		socket.write_string(data) or {
			eprintln(err)
			exit(-1)
		}
	}
}

fn listen_for_messages(mut socket &net.TcpConn) {
	for {
		mut data := []u8{len: 1024}
		socket.read(mut data) or {
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
	app.pseudo_is_error = app.pseudo_text.len < 8
}
