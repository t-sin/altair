# Altair - Little Programmable Synthesizer

Altair is a little programmable synthesizer program.
Its behavior can be programmed with Forth-like (PostScript-like) language.

Altair has these features below:

- Basic oscillators (Saw)
- Step Sequencer
- Parameter events for sound-synthesis modules
- These are programmable with small subset of PostScript

## Installation

Now the way to use and play with Altair is building it yourself from its source.
To install Nim, see this page <https://nim-lang.org/install.html>.
If you installed Nim, to type in Altair source directory:

```sh
$ nimble build
```

so the binary `altair` will be created, execute it.

## Usage

Because Altair require that its behavior is defined as *Tapir Forth* source code.
To play with Altair, you should custum synthesizer behavior to write *.tf file.
However, there is a sapmle file to try Altair (see <examples/>).

Type like this to run Altair:

```
altair ./examples/04-saw.tf
```

## Author

- TANAKA Shinichi (<shinichi.tanaka45@gmail.com>)

## License

This program *Altair* is licensed under the GNU General Public License Version 3. See [LICENSE](LICENSE) for details.
