
my-otr Shell Script
===================

The missing command-line tool for otr.datenkeller.net!

Finally! :)

Useful:
- to automate usage of otr.datenkeller.net, e.g. to be able to programm recordings of your favorite shows via a cron job :)
- because it provides much better filtering than the website!

Tested on MacOS and Linux


Dependencies
------------

- Shell (script is /bin/dash compatible, so only uses POSIX shell features)
- awk
- Some otr decode tool (if you want to decode ;))
  - [otrtool](https://github.com/otrtool/otrtool): Runs under Linux + MacOS
  - [otrdecoder ("Decoder"/"Dekoder")](https://www.onlinetvrecorder.com/v2/software/): Runs under Linux + MacOS
- wget and aria2c or curl


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
      -Q  | --quiet        Supress any regular status output of the script (search results will still be printed). Independent of VERBOSE and DEBUG !
      -V  | --verbose      Turn VERBOSE output ON.
      -D  | --debug        Turn DEBUG output ON.
      -DD | --deep-debug   Turn DEBUG for subcommands ON called by this script: my-otr.awk, decode_cmd as returned by get_decode_cmd()
                           Independent of regular debug output (--debug).
      -l  | --log          Turn LOGGING of any output (verbose, debug, deep-debug) ON. Logs to LOGFILE '/var/log/mine/me/my-otr.log' by default.
      -L  | --no-log       Prevent logging to LOGFILE '/var/log/mine/me/my-otr.log'.
      --log-file FILE      Set LOGFILE to FILE.
      -F  | --force        Do FORCE things - you'll be informed (in VERBOSE mode) where this can help.
    
    COMMAND can be:
      [--]help     shows this usage information
    
      [--]decode   <OTRFILE> [<OTRFILE> [..]] [<OUTPUT-DIR> defaults to /dl/,tv]
                   <OTRFILE> can be '-', then the OTRFILE(s) are read from stdin !
                   The script will stop decoding and quit on errors.
                   <OUTPUT-DIR> needs to be a directory that exists.
                   This command is by default SILENT. Use --verbose to see decoded filenames.
    
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
                           '@HH:' or '@HHh' or '@HH:MM' <<< e.g. "@20h" search only for shows STARTING AT the provided time
                           '>HH:' or '>HHh' or '>HH:MM' <<< e.g. ">20h" search only for shows STARTING AFTER (or ON; so including) the provided time
                           '<HH:' or '<HHh' or '<HH:MM' <<< e.g. "<20h" search only for shows STARTING BEFORE (or ON; so including) the provided time
                           '@Mon' .. '@sun'  <<< search only for shows GIVEN AT CERTAIN WEEKDAY
                           '@DD' <<< search only for shows with a DURATION EQUAL the provided length in minutes
                           '<DD' <<< search only for shows with a DURATION LESS (or EQUAL; so including) the provided length in minutes
                           '>DD' <<< search only for shows with a DURATION MORE (or EQUAL; so including) the provided length in minutes
    
      [--]dl|download  <<< reads URL to download from stdin
                       <<< will NOT re-download if decoded file already exists; except if FORCE is used
    
      [--]get          <<< LIKE --dl, but will after successful download automatically DECODE (like calling my-otr --decode)!
    
    
    Uses CONFIG FILE '~/.my-otr.conf'. You can change location with --conf parameter!
    
    SOME DEFAULT VALUES FROM CONFIG FILE:
      QUIET   = '' <<< if QUIET is set (so != ''), then by default this script will supress any regular status output (search results will still be printed) 
      LOG     = '1' <<< if LOG is set (so != ''), then by default this script will redirect all output to this LOGFILE '/var/log/mine/me/my-otr.log'! (see --no-log above)
      VRB     = '' <<< if VRB is set (so != ''), then by default this script will print VERBOSE output (see --verbose above)
      DBG     = '' <<< if DBG is set (so != ''), then by default this script will print DEBUG output (see --debug above)
      DEEPDBG = '' <<< if DBG is set (so != ''), then by default this script will print DEBUG output (see --deep-debug above)
      FORCE   = '' <<< if FORCE is set (so != ''), then by default this script will FORCE some things (see --force above)
    
    EXAMPLES:
      # Search all Bares fuer Rares given on channel 'zdf', aired on or after 2020-02-28 and only shows given at exactly 15h05:
      my-otr search "bares fuer rares" @zdf ">2020-02-28" @15:05
    
      # Simply download ALL available Bares fuer Rares and decode them (but starting with the OLDEST -- hence the 'tac'):
      my-otr search bares fuer rares|tac|my-otr get
    
    REMARKS:
    ### ALL OUTPUT (regular status ouput (notice), VERBOSE, DEBUG output) all goes to STDERR /or/ to LOGFILE.
    ### ANY OUTPUT useful to be piped to next tool will go to STDOUT !
    
