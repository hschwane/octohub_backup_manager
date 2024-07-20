function sendPost(content) {
	return fetch('/', {
		method: "POST",
		headers: { "Content-Type": "text/plain" },
		body: content
	})
}

function reboot() {
	const confirmed = confirm("Are you sure you want to reboot the system?")
	if(confirmed) {
		sendPost("reboot")
	}
}

function shutdown() {
	const confirmed = confirm("Are you sure you want to shut down the system?")
	if(confirmed) {
		sendPost("shutdown")
	}
}

function makeBackup() {
	const confirmed = confirm("Are you sure you want to create a new Backup? Do not shut down the system until the backup was completed. This can take a while.")
	if(confirmed) {
		sendPost("start_backup").then(_=>{
			location.reload();
		})
	}
}

function restoreBackup(filename) {
	const confirmed = confirm("Are you sure you want to restore this Backup? Do not shut down the system until the backup was completed. This can take a while.")
	if(confirmed) {
		sendPost("restore_backup "+filename).then(_=>{
			location.reload();
		})
	}
}

function removeBackup(filename) {
	const confirmed = confirm("Are you sure you want to remove this Backup?")
	if(confirmed) {
		sendPost("remove_backup "+filename).then(_=>{
			location.reload();
		})
	}
}