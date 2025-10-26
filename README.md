# numi-repl

A tiny interactive **bash REPL** for [`numi-cli`](https://github.com/nikolaeu/numi).  
Type expressions, reuse the previous result with `prev`, navigate history with ↑/↓, and (optionally) see the evaluated command in debug mode.

## Features
- Interactive loop with readline (↑/↓ history, editing)
- `prev` substitution – type prev to use the output of the previous calculation on the next one
- Debug mode prints the evaluated `numi-cli` command
- Checks `numi-cli` availability on start
- Clears the terminal on launch

## Requirements
- `bash` (Linux/macOS/WSL)
- `numi-cli` in `PATH`  
  → Install instructions: https://github.com/nikolaeu/numi

## Install
```bash
curl -o numi-repl.sh https://raw.githubusercontent.com/wizzor/numi-repl/refs/heads/main/numi-repl.sh
chmod +x numi-repl.sh
```

## Usage
```bash
./numi-repl.sh           # normal mode
./numi-repl.sh --debug   # debug mode
# or:
NUMI_REPL_DEBUG=1 ./numi-repl.sh
```

On launch, the terminal is cleared and you’ll see:
```
type exit or ctrl-d to exit
```

## Examples
```
numi> 1+1
                                       2
numi> prev + 1
                                       3
numi> prev*prev
                                       9
```

In **debug** mode you’ll also see:
```
[debug] numi-cli -- 2 + 1
```

## Notes
- `prev` stores the **raw stdout** from `numi-cli`.
- If you use `prev` before any result exists, the script warns and does not run `numi-cli`.
- If `numi-cli` returns an error, it’s shown in red and `prev` is unchanged.
- The script auto-detects your `sed` flavor to ensure `prev` substitution works across distros.

## Troubleshooting
- If `prev` doesn’t substitute, ensure you’re running **bash** and that your `sed` supports extended regex (`-E` or `-r`). The script auto-detects which flag to use.
- On very narrow terminals, right-alignment may wrap long results.
