# Scripts in skills

Put a step in `scripts/` when it is deterministic and the host would otherwise rewrite the same code every run: building a PDF, checking a toolchain, running a loop driver. The host runs the script and reads only its output, so the script's source never costs context.

## Rules

- Run from the skill root with a relative path: `bash scripts/build_pdf.sh report.md`. Say in `SKILL.md` whether the host should run the script or only read it.
- Prefer `bash` and the Python standard library. If a script needs anything else, check for it first and fail with one clear line telling the user what to install. List it in the `compatibility` frontmatter field too.
- Handle errors inside the script. Print a short, specific message and a non-zero exit code; do not let a raw stack trace be the interface.
- Explain every magic number with a comment.
- Write output where the user can find it (the current project, or a path the user passes), never inside the skill folder. Installed skills may be read-only symlinks or copies.
- Always give the host a manual path in `SKILL.md` for when it has no shell.
- Make scripts executable (`chmod +x`) and start them with a shebang.
