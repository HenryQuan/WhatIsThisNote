# Releases

Release notes for each version of WhatIsThisNote, newest first. Each file is
named after the version (`0.1.md`, `0.2.md`, ...) and describes what shipped.

| Version | Notes | Summary |
| --- | --- | --- |
| 0.1 | [0.1.md](0.1.md) | First real release: note reading, practice, metronome, chord lab and builder. |

## Adding a release

1. Copy the previous file to the new version number, e.g. `cp 0.1.md 0.2.md`.
2. Update the heading and contents.
3. Add a row to the table above.
4. Tag the commit, e.g. `git tag -a v0.2 -m "WhatIsThisNote 0.2"`, then
   `git push origin v0.2`.
