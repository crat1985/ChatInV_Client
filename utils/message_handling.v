module utils

import os

pub fn (mut app App) send_messages() {
	for {
		data := os.input("")
		app.socket.write_string(data) or {
			eprintln(err)
			exit(-1)
		}
	}
}

pub fn (mut app App) listen_for_messages() {
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