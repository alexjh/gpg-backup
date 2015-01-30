GPG / Duplicity Backup Scheme
=============================

This Makefile takes the list of GPG keys from your keyring and exports
them as QR barcodes suitable for printing. They can be scanned and
recovered with various tools like zbarimg / zbarcam, smartphone app,
etc.

It is meant to be used with an account made specifically for backing up via S3,
so a test transaction is made to confirm the S3 credentials are correct.

The credentials.txt file should contain the following variables:

* `<key>_PASSPHRASE`: A passphrase for each GPG key that should be backed up.
* `S3_ACCESS_KEY`
* `S3_SECRET_KEY`
* `S3_URL`

If all of the GPG keys are not meant to be backed up, the `GPG_KEYS` variable
could be changed to be a space separated list of the specific keys.

One can find the GPG key ids by running:
    `gpg --list-keys --with-colons --fast-list-mode | grep pub | awk -F: '{ print $$5 }'`

## Requirements ##

* paperkey
* qrencode
* [aspectpad script](http://www.fmwconcepts.com/imagemagick/aspectpad/index.php)

## TODO ##

* A more secure mode where the `key_PASSPHRASE` variable is prompted for and used
  to generate the credentials.jpg file rather than storing it on disk. S3
  credentials are likely already on disk for the duplicity script, so these are
  not as much as a concern.
* Store the exported images on a ramdisk?
* Securely delete the files via shred?
* Print the files via a pipe so they never hit the disk?
