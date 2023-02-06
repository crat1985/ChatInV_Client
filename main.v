module main

import net
import os

fn main() {
	mut socket := net.dial_tcp("localhost:8888") or {
		panic(err)
	}

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
	mut data := []u8{len: 1024}
	for {
		socket.read(mut data) or {
			eprintln(err)
			break
		}
		print(data.bytestr())
		flush_stdout()
	}
	exit(-1)
}
