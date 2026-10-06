# Agent Instructions

Use the Copilot instruction files as AGENTS.md-like context sources for this
workspace.

- For all work in this repository, read `.github/copilot-instructions.md`.
- For work under `../bin/data/jhc`, also read
  `../bin/data/jhc/.github/copilot-instructions.md`.

Treat these files as project guidance: prefer their conventions when editing
code or data, and mention any conflicts with the user's request before making
non-obvious changes.

## Compilation Fallback

The Copilot instructions prefer VS Code tasks for builds. If those tools are not
available, compile only the Linux `drl` executable with WSL's native FPC. Do not
build WADs or run the game unless explicitly asked.

This command verifies the executable build without replacing the playable binary:

```bash
fpc -Px86_64 -Mobjfpc -Scgi -Cirot -O1 -gw3 -gl -l -vewnhibq -vm6058 -vm5024 -vm4105 -vm4104 -vm4081 -vm4080 -vm4079 -vm4056 -vm4055 -vm3250 -Fi/mnt/d/drl/bin -Fi/mnt/d/fpcvalkyrie/libs -Fi/mnt/d/fpcvalkyrie/src -Fu/mnt/d/fpcvalkyrie/libs -Fu/mnt/d/fpcvalkyrie/src -Fu/mnt/d/drl/src -FU/mnt/d/drl/tmp -o/mnt/d/drl/tmp/drl_compile_check drl.pas
```

Compile only when asked or if doing significant Pascal code changes.
