module main

import net
import os
import time

fn main() {
	mut socket := net.dial_tcp("localhost:8888") or {
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
