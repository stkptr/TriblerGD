# TriblerGD

TriblerGD is a simple client for Tribler's REST API. If Tribler core is
installed on a headless machine, TriblerGD can connect to it and control
downloads, change settings, and browse for torrents.

**Warning**: connecting to a remote Tribler instance is **insecure**, use SSH
tunneling to encrypt the connection.

## Current features

- Browse popular torrents
- Search for torrents by text, with filtering (NSFW, deleted, but not category)
- Change settings
- View downloading/seeding torrents
- Download new or manage in progress torrents from the popular or search pages
- Add new torrents from file, magnet, or infohash, supporting hex and base32

## Future features

- Improved search
- Improved settings dialog
- Creating torrents (files must be on the host machine)
- CLI interface
- V2 torrent support (requires [Tribler#5556][tribler-5556])

## License

CC0 or Unlicense, at your decision.

[tribler-5556]: https://github.com/Tribler/tribler/issues/5556
