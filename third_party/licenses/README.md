# Release license input

The release packaging script intentionally does not download legal text. Before
packaging, provide the official unmodified `LGPL-3.0-only.txt` file through the
`-QtLicenseFile` parameter. The script copies that file into the installer
license page; it does not commit a machine-specific SDK path to the repository.

Qt must remain dynamically linked in the release. Any additional third-party
library introduced later must add its exact version, license and redistributable
license text before a public package is produced.
