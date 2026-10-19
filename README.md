my-otr
======

The missing command-line tool for otr.datenkeller.net and onlinetvrecorder.com:
search with better filters than the website, download, and decode -- all of it
scriptable, e.g. to fetch the new episodes of your shows every night.

- `search`: the best file of each recording, filtered by channel, day, weekday,
  start time and duration.
- `get`: downloads the names `search` printed, skips a recording already here in
  an equal or better quality, and decodes what it fetched.
- Decodes both of OTR's formats itself: `.otr2` (since 2026) and `.otrkey`
  (before). The decoded file keeps OTR's name with its container's extension
  (`..._TVOON_DE.HQ.mp4`), is checked against the checksum OTR sends, and stays
  byte for byte the recording: my-otr adds no watermark.

Written from OTR's own CLI decoder (which states no licence, so none of its code
is in here): `my-otr update-check <ZIP>` lists what a new release of it changed
in the protocol.


Dependencies
------------

- Python 3.9 or newer
- [cryptography](https://pypi.org/project/cryptography/) -- my-otr installs it
  itself on first use, into its own environment `~/.python.venv/my-otr`
- [aria2c](https://aria2.github.io/) for the downloads


Install
-------

- put `my-otr` somewhere in your PATH
- `my-otr --create-config ~/.my-otr.conf`, then enter your credentials for
  https://otr.datenkeller.net and https://www.onlinetvrecorder.com in it
- `my-otr --run-tests` to see it work here


Usage
-----

    usage: my-otr [OPTIONS] <COMMAND> [<ARGS>]

    Search otr.datenkeller.net, download with aria2c, and decode OTR's .otr2 and
    .otrkey files. Results go to stdout; everything else to stderr and the LOGFILE.

    COMMANDS
      search <TITLE..> [<FILTER>..]   the best file of each recording, oldest
                                      first, one name per line. FILTERs ('@' ones
                                      may repeat; quote those with < and >):
          @<channel>                    on this channel (as otr.datenkeller.net names it)
          '>2026-01-31' '<2026-03-01'   on or after / on or before the day
          @2026-02-14                   on the day
          @20h @20:15                   starting at
          '>20h' '<22:30'               starting from / until -- '>22h' '<02h'
                                        spans midnight
          @Mon .. @Sun                  on the weekday
          @45 '>90' '<30'               lasting exactly / at least / at most N minutes
      get [--no-decode]               download the names (or URLs) on stdin into
                                      the current folder -- not one whose copy
                                      here is as good -- then decode every complete
                                      .otr2 / .otrkey in it; --no-decode: download only
      dl                              the same as get --no-decode
      decode <FILE>.. [<DIR>]         decode into DIR (else DEFAULT_DECODE_OUTP_DIR);
                                      FILE '-': the names on stdin
      login                           log in to otr.datenkeller.net (get does)
      update-check <ZIP>              what a new release of OTR's decoder changed in
                                      the protocol my-otr speaks

      Decoding removes the source once the result is complete and -- where OTR
      sends one -- matches its checksum. The quality taken: HQ, then the small
      ones, then HD (HD first with OTR_QUALITY_CAP="HD").

    OPTIONS
      -Q, --quiet              nothing on the terminal but results and errors
      -V, --verbose            also each request, and each skip with its reason
      -D, --debug              also the diagnostics (~~~); implies -V
      -F, --force              log in, download and decode again what is here
      -l, --log / -L, --no-log   keep the LOGFILE record / keep none
      --log-file <FILE>        record into FILE (implies -l)
      --config <FILE>          read FILE instead of searching for one
      --create-config [<FILE>] the default config, to stdout or into a new FILE
      --run-tests [<FILTER>]   the built-in tests (TAP); FILTER: part of a name
      --version                the exact build
      -h, --help               this

      The old spellings --search --get --dl --download --decode --login still work.

    CONFIG  KEY="value" lines, read and never run -- the first found of
      $MY_OTR_CONFIG, --config <FILE>,
      /LINKS/default/my-otr.conf, /LINKS/default/my-otr, ~/.my-otr.conf, /etc/my-otr.conf, /usr/local/etc/my-otr.conf
      A <FILE>.GLOBAL beside it is read first, the file itself on top.

    EXAMPLES
      my-otr search "bares fuer rares" @zdf '>2026-02-28' @15:05
      my-otr search "bares fuer rares" | my-otr get
