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
- Programmed recordings: `record` a show (every day it is on) or a one-off (a
  date, a range), and `refresh` fetches the new ones into each one's folder --
  nightly, as a LaunchDaemon on macOS (`--install`).

Written from OTR's own CLI decoder (which states no licence, so none of its code
is in here): `my-otr update-check <ZIP>` lists what a new release of it changed
in the protocol.


Dependencies
------------

- Python 3.9 or newer
- [cryptography](https://pypi.org/project/cryptography/) -- for decoding only:
  my-otr installs it itself the first time it decodes, into its own environment
  `~/.python.venv/my-otr`
- [aria2c](https://aria2.github.io/) for the downloads


Install
-------

- put `my-otr` somewhere in your PATH
- `my-otr --create-config ~/.my-otr.conf`, then enter your credentials for
  https://otr.datenkeller.net and https://www.onlinetvrecorder.com in it
- `my-otr --run-tests` to see it work here


Programmed recordings
---------------------

`my-otr record <FOLDER> <TITLE> [<FILTER>..] [--max <N>]` takes the same words
as `search`, shows what the search finds now, and adds one `record` line to
`RECORDINGS_FILE` (default `~/.my-otr.recordings`; an editor is as good -- the
file explains itself), the folder and the title always in `''`. FOLDER is
absolute, or below `LIBRARY_DIR`.

The recordings are a file of their own, not lines in the config: the config
under `/LINKS/default` is root's, while `record` runs as you and must be able
to write its lines.

    my-otr record 'series/bares/' 'bares fuer rares' @zdf '>8d' @15:05        # every day it is on
    my-otr record 'series/heute/' 'heute show' @zdf '>7d' --max 2             # weekly, 2 at most
    my-otr record '/Volumes/films/' 'tatort' @ard @2026-11-03 @20:15 --max 1    # one evening

- `my-otr refresh` searches each recording and gets the new ones into its
  folder (`--dry-run`: search only; `refresh <TEXT>`: only the lines holding
  it). Each search and get runs as a child with its own timeout
  (`SEARCH_TIMEOUT`, `GET_TIMEOUT`): a hung one is killed with all it started.
  One failing never stops the others; the run fails at the end and, when
  nobody watches, mails through `FAIL_MAIL_CMD`. When every search fails, the
  first line says OTR was out of reach -- the network, or a firewall prompt
  nobody answered.
- Before a download, refresh looks for the recording in the whole library
  (`LIBRARY_DIR`, and every absolute record folder): any file whose name
  carries OTR's `_YY.MM.DD_HH-MM_<channel>_<minutes>_TVOON_DE` -- the part a
  renamed file keeps -- is that recording, wherever it was moved. And what
  refresh fetched is noted in `<RECORDINGS_FILE>.fetched`, one name a line,
  so one deleted after watching is not fetched again either. A recurring
  line can therefore search a week back (`'>8d'`): a file OTR offers late,
  or a night that failed, is still caught.
- `refresh --since <DATE>` takes DATE as every line's from-date, for that run
  only: a catch-up after a long gap (`--dry-run` first shows what it would
  fetch).
- A one-off more than `PAST_AFTER_DAYS` (7) after its last day is outdated: no
  longer searched, and named in each run -- "please check/remove". my-otr
  never removes a line itself.
- `RUN_AFTER_REFRESH`: a command run after each full refresh.
- `my-otr list` shows the lines; bare `my-otr` the state -- the recordings,
  the nightly job, the last run.
- `my-otr --install` (root) writes the LaunchDaemon: daily at `RUN_AT` as
  `RUN_AS`, or through `FDA_LAUNCHER` -- a launcher that runs my-otr with Full
  Disk Access and drops to its own user. Its stdout and stderr go to
  `LAUNCHD_LOG`; it gets `LAUNCHD_PATH` (launchd's own PATH would find neither
  Homebrew's Python nor aria2c). A `RUN_AT` between 02:00 and 02:59 is refused:
  launchd fires those twice on the night the clocks go back.


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
          '>1d' '>7d'                   since one / seven days ago (a recurring record line)
          @2026-02-14                   on the day
          @20h @20:15                   starting at
          '>20h' '<22:30'               starting from / until -- '>22h' '<02h'
                                        spans midnight
          @Mon .. @Sun                  on the weekday
          @45 '>90' '<30'               lasting exactly / at least / at most N minutes
      get                             download the names (or URLs) on stdin into
                                      the current folder -- not one whose copy
                                      here is as good -- then decode every complete
                                      .otr2 / .otrkey in it
      dl                              get without the decode: download only
      decode <FILE>.. [<DIR>]         decode into DIR (else DEFAULT_DECODE_OUTP_DIR);
                                      FILE '-': the names on stdin
      login                           log in to otr.datenkeller.net (get does)

    PROGRAMMED RECORDINGS -- RECORDINGS_FILE, one `record` line each
      record <FOLDER> <TITLE> [<FILTER>..] [--max <N>]
                                      program a recording: FOLDER absolute, or below
                                      LIBRARY_DIR; TITLE and FILTERs as for search
                                      ('>8d' recurring, @DATE or a range one-off);
                                      --max: at most N new ones a refresh. Shows what
                                      the search finds now, then adds the line
      list                            the recordings programmed (not OTR's: search
                                      finds those); an outdated one is marked
      refresh [<TEXT>] [--since <DATE>] [--dry-run]
                                      each recording: search, then get the new ones
                                      into its folder -- new: no file anywhere below
                                      LIBRARY_DIR carries OTR's slot (date, time,
                                      channel, length -- kept by a renamed file),
                                      and not in <RECORDINGS_FILE>.fetched, the
                                      names refresh fetched (a deleted one too);
                                      TEXT: only lines holding it; --since: DATE as
                                      every line's from-date, this run only (a line
                                      with its own @DATE keeps it); --dry-run: search
                                      only. One failing never stops the others. A
                                      one-off PAST_AFTER_DAYS after its last day is
                                      outdated: not searched, named
      (bare)                          a short usage line and the state
      update-check <ZIP>              what a new release of OTR's decoder changed in
                                      the protocol my-otr speaks

      Decoding removes the source once the result is complete and -- where OTR
      sends one -- matches its checksum. The quality taken: HQ, then the small
      ones, then HD (HD first with OTR_QUALITY_CAP="HD"). A file in a quality
      my-otr does not know yet is skipped, with a WARNING naming it.

    OPTIONS
      -Q, --quiet              nothing on the terminal but results and errors
      -V, --verbose            also each request, and each skip with its reason
      -D, --debug              also the diagnostics (~~~); implies -V
      -F, --force              log in, download and decode again what is here
      -l, --log / -L, --no-log   keep the LOGFILE record / keep none
      --log-file <FILE>        record into FILE (implies -l)
      --config <FILE>          read FILE instead of searching for one
      --create-config [<FILE>] the default config, to stdout or into a new FILE
      --install / --uninstall  the nightly refresh as a LaunchDaemon (root): RUN_AS,
                               RUN_AT, LAUNCHD_LABEL, LAUNCHD_LOG, LAUNCHD_PATH,
                               FDA_LAUNCHER (a launcher that runs my-otr)
      --test-mail              one mail through FAIL_MAIL_CMD, the failure mail's path
      --run-tests [<FILTER>]   the built-in tests (TAP) -- all, or those whose name holds FILTER
      --version                the exact build
      -h, --help               this


    CONFIG  KEY="value" lines, read and never run -- the first found of
      $MY_OTR_CONFIG, --config <FILE>,
      /LINKS/default/my-otr.conf, /LINKS/default/my-otr, ~/.my-otr.conf, /etc/my-otr.conf, /usr/local/etc/my-otr.conf
      A <FILE>.GLOBAL beside it is read first, the file itself on top.

    EXAMPLES
      my-otr search "bares fuer rares" @zdf '>2026-02-28' @15:05
      my-otr search "bares fuer rares" | my-otr get
      my-otr record '/Volumes/films/' 'tatort' @ard @2026-11-03 @20:15 --max 1
