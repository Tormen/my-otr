
my-otr Shell Script
===================

The missing command-line tool for https://otr.datenkeller.net!

Finally! :)

Useful:
- to automate usage of https://otr.datenkeller.net, e.g. to program recordings of your favorite shows :)
- because it provides much better filtering than the website!

Tested on MacOS and Linux

Dependencies
------------

- Shell (script is /bin/dash compatible, so only uses POSIX shell features)
- awk
- Some otr decode tool (if you want to decode ;))
  - [otrtool](https://github.com/otrtool/otrtool): Runs under Linux + MacOS
  - [otrdecoder ("Decoder"/"Dekoder")](https://www.onlinetvrecorder.com/v2/software/): Runs under Linux + MacOS

Install
-------

Copy my-otr somewhere. Run it. It'll guide you ;)

Otherwise you first need to:
- install `my-otr` somewhere
- run `my-otr --conf >~/.my-otr.conf` to create your CONFIG FILE
- edit the CONFIG FILE:
  - #Mandatory# Enter your credentials for https://otr.datenkeller.net
  - #Optionally# if you want to DECODE:
    - Enter credentials for for https://www.onlinetvrecorder.com
    - Adapt "get_decode_cmd()" in the CONFIG FILE (especially if you don't want to use otrtool !)
- place my-otr.awk somewhere (e.g. ~/.my-otr.awk /or/ BESIDE my-otr /or/ edit OUR_AWK_SCRIPT variable in the CONFIG FILE.

Usage
-----

    usage: my-otr/my-otr [OPTIONS] <COMMAND> [[PARAM] [..]]
    
    OPTIONS:
      -C  | --conf [FILE]  If FILE is provided: Use FILE as config file (instead of '/Users/me/.my-otr.conf').
                           If called WITHOUT FILE this will print the DEFAULT CONFIG.
                           You can use this to create your default config file:
                             my-otr --conf > "/Users/me/.my-otr.conf"
      -D  | --debug        Turn DBG output ON.
      -DD | --deep-debug   Turn DBG output ON; also for subcommands called by this script: my-otr.awk, decode_cmd as returned by get_decode_cmd()
      -Q  | --quiet        Turn verbose output OFF.
      -l  | --log          Do log to LOGFILE '/var/log/mine/my-otr.log'.
      -L  | --no-log       Prevent logging to LOGFILE '/var/log/mine/my-otr.log'.
      -F  | --force        Do FORCE things - you'll be informed (in VERBOSE mode) where this can help.
    
    COMMAND can be:
      [--]help     shows this usage information
    
      [--]decode   <OTRFILE> [<OTRFILE> [..]] [<OUTPUT-DIR> defaults to ]
                   <OTRFILE> can be '-', then the OTRFILE(s) are read from stdin !
                   The script will stop decoding and quit on errors.
                   <OUTPUT-DIR> needs to be a directory that exists.
    
      [--]login    <<< will NOT re-loging if cookie file found; except if FORCE is used <<< #TODO# automatically re-login in case cookie is not valid anymore
    
      [--]search   <<< allow filtering via additional parameters: 
                       MANDATORY parameter: 
                           TITLE SEARCH TEXT <<< text to search for in titles (this is what you would type into searchbox on otr.datenkeller.net!)
                                             <<< will STOP to take parameters as TITLE-SEARCH-TEXT when a ',' is found!
                       OPTIONAL parameters: All parameters starting with '@' can be provided multiple times!
                           DESCRIPTION SEARCH TEXT <<< OPTIONAL 2nd text parameter; this will be used to search in the description <<< NOT YET IMPLEMENTED !!! #TODO#
                           @channel <<< search only in provided channel name (channel name must match otr.datenkeller.net)
                           '>date' <<< search only for shows AFTER (or ON; so including) a given date; in format: 2021-11-24
                           '<date' <<< search only for shows UP TO (or ON; so including) a given date; in format: 2021-11-24
                           '@date' <<< search only for shows AT a given date; in format: 2021-11-24
                           '@HH:' or '@HH:MM' <<< search only for shows STARTING AT the provided time
                           '>HH:' or '>HH:MM' <<< search only for shows STARTING AFTER (or ON; so including) the provided time
                           '<HH:' or '<HH:MM' <<< search only for shows STARTING BEFORE (or ON; so including) the provided time
                           '@Mon' .. '@sun'  <<< search only for shows GIVEN AT CERTAIN WEEKDAY
                           '@DD' <<< search only for shows with a DURATION EQUAL the provided length in minutes
                           '<DD' <<< search only for shows with a DURATION LESS (or EQUAL; so including) the provided length in minutes
                           '>DD' <<< search only for shows with a DURATION MORE (or EQUAL; so including) the provided length in minutes
    
      [--]dl|download  <<< reads URL to download from stdin
                       <<< will NOT re-download if decoded file already exists; except if FORCE is used
    
      [--]get          <<< LIKE --dl, but will after successful download automatically DECODE (like calling my-otr --decode)!
    
    
