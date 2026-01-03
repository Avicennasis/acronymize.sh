
# acronymize.sh

Generate a playful “acronym expansion” from input text by mapping each letter (in order) to a randomly selected dictionary word that starts with that letter.

Example concept:

Input:
```
./acronymize.sh Make

```

Output (will vary):
```

Maui Accountancy Koontz Emigrant

````

## Features

- **Readable output for multi-word input**: prints **one output line per input word**.
- **Per-occurrence randomization**: repeated letters can produce different words within the same run.
- **Input sanitization**:
  - Splits input on whitespace to preserve word boundaries.
  - Removes non-alphabetic characters from each word before processing.
- **Title Case output**: each generated word is capitalized (first letter uppercased).
- **Efficient implementation**: scans the wordlist once and performs all selection in `awk` (no per-letter external pipelines).
- **Custom wordlists**:
  - `-w /path/to/wordlist`
  - `WORDLIST=/path/to/wordlist`

## Requirements

- Bash
- `awk`
- A wordlist file (default: `/usr/share/dict/words`)

On many Linux systems, `/usr/share/dict/words` is provided by a package commonly named `words` (or similar). If your system does not have a default wordlist, provide one using `-w` or `WORDLIST`.

## Installation

Clone the repository and make the script executable:

```bash
chmod +x acronymize.sh
````

## Usage

```bash
./acronymize.sh [-w WORDLIST] [text...]
```

### Examples

Single word:

```bash
./acronymize.sh test
```

Multiple words (quotes optional):

```bash
./acronymize.sh Make Acronyms Great Again
```

Custom wordlist using `-w`:

```bash
./acronymize.sh -w ./words.txt "hello world"
```

Custom wordlist using `WORDLIST`:

```bash
WORDLIST=./words.txt ./acronymize.sh hello world
```

## Output format

* Each **input word** becomes one **output line**.
* Each **letter** in the input word becomes one **output word**.
* Non-alphabetic characters are removed from each input word before processing.

Example:

```bash
./acronymize.sh "Hello, world!"
```

Possible output:

```
Horizon Ember Lantern Lichen Orbit
Warden Orbit Rivulet Lantern Druid
```

## Word selection behavior

For each letter occurrence:

1. The script selects a random dictionary word that begins with that letter.
2. Repeated letters are randomized independently.

To reduce short-run repetition for the same starting letter, candidate words for a given letter are shuffled and consumed sequentially, then reshuffled when exhausted.

## Handling missing matches

If no dictionary entry matches a given letter, the script emits a placeholder token:

* `(no-match:x)`

## Options and environment variables

### `-w PATH`

Use a custom wordlist.

### `WORDLIST`

Environment variable alternative to set the wordlist path (overridden by `-w`).

## Exit codes

* `0` success
* `1` wordlist not readable
* `2` invalid usage (missing input or no alphabetic characters)


## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
## Credits
**Author:** Léon "Avic" Simmons ([@Avicennasis](https://github.com/Avicennasis))
