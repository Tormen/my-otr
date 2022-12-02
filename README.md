
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

