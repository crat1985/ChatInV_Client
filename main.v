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
	pseudo_text string
	pseudo_is_error bool
	password_text string
	password_is_error bool
	socket &net.TcpConn
	addr string
	addr_placeholder string
	port string
	port_placeholder string
}

fn main() {
	mut app := &App{
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
						justify: ui.center
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

					ui.textbox(
						placeholder: app.addr_placeholder
						on_change: app.addr_changed
					)

					ui.textbox(
						placeholder: app.port_placeholder
						on_change: app.port_changed
						is_numeric: true
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
	mut is_connected := true
	app.socket.write([]u8{len: 1}) or { is_connected = false }
	if is_connected {
		confirm := ui.confirm("Veux-tu stopper toutes les autres connexions actives ?")
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

fn (mut app App) addr_changed(it &ui.TextBox) {
	app.addr = it.text
}

fn (mut app App) port_changed(it &ui.TextBox) {
	app.port = it.text
}
