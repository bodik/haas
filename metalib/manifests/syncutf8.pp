# == Resource: metalib::syncutf8
#
# TODO documentation
#
define metalib::syncutf8(
	$src_dir,
	$dest_dir,
) {
	exec { "syncutf8 $src_dir $dest_dir":
		command => "/usr/bin/rsync --delete --recursive --links $src_dir/ $dest_dir 1>/dev/null",
		unless => "/usr/bin/diff -rua $src_dir $dest_dir 1>/dev/null"
	}
}

