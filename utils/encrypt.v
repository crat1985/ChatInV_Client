module utils

fn (mut app App) encrypt_string(text string) []u8 {
	return app.box.encrypt_string(text)
}

fn (mut app App) decrypt_string(data []u8) !string {
	decrypted := app.box.decrypt_string(data)
	if decrypted.is_blank() {
		return error('Failed to decrypt data')
	}
	return decrypted
}
