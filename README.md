# ssbackup
ssbackup -  a tool for making snapshot-style backups

## ssbackup
This tool is an implementation of the snapshot-style-backup
method that is described in http://www.mikerubel.org/computers/rsync_snapshots/.

It makes a backup every time it is called, holding a specified number
of backups, so you can go back to older versions. Instead of making a
full copy every time, it hard-links files that have not changed since
the last run, so normaly using only a fraction of the space.  Every
snapshot looks like a full copy.

## ssbackup-batch
A tool for calling ssbackup.
