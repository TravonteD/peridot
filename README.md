# peridot

A modern terminal MPD (Music Player Daemon) client

## Installation

### Dependencies

- `libmpdclient`
- `termbox`
- `crystal`
- `shards`

### From Source

1. Install the dependencies from you package manager
2. `cd` into the directory and run `shards install`
3. run `shards build`
4. The binary will be in the `bin/` directory

## Usage

### Launching
Run the command `peridot`

### Keybindings
- "p" : toggle play/pause
- "s" : stop
- "j": move down
- "k": move up
- "ctrl-l": move to the library window
- "ctrl-p": move to the playlist window
- "ctrl-q": move to the primary window
- "Enter" : play the selection

## Development

Install the dependencies and run `shards install`

## Contributing

1. Fork it (<https://github.com/travonted/peridot/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
