Useful for verifying the integrity of static files over time to detect bit rot and other corruption.

Updater generates checksums for all files in a directory, including subdirectories and writes those checksums into a file. Updater does not recalculate checksum for files already calculated and removes checksums for files which no longer exist.

If you want to recalculate a checksum for a file. You will have to manually edit the checksum file and remove the correct line. You can also recalculate all checksums by deleting the checksums file.

Verifier will inform you which files are OK, BAD, and MISSING. Verifier will not modify the checksums file no matter what.
