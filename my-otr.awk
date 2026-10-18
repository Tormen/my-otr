#!/usr/local/bin/gawk -f

# 1027 == highest used errCode

function usage() {
  print "usage: cat /tmp/x|  awk -v DBG=$DBG -f " ARGV[0] " <COMMAND>"
  print "usage: awk -v DBG=$DBG -f " ARGV[0] " <COMMAND> <FILE>"
  print "usage: awk -v DBG=$DBG -f " ARGV[0] " <FILE> <COMMAND>"
  print ""
  print "   <COMMAND> must be one of:"
  print "       help - show this help"
  print "       search"
  print "       get"
  print ""
  print "Uses only VRB."
  exit;
}

########################################################################################3

function err(errnr, errmsg, exitcode) { 
  if (exitcode == "") exitcode = 1; regex="^"DBGPFX_DEFAULT; sub(regex, "", errmsg);
  if (length(FILENAME) > 0) { tmp1=sprintf("'%s' @ %d ", FILENAME, FNR); tmp2=sprintf("\nvim +%s '%s'\n", FNR, FILENAME); }
  ERRCODE=sprintf("%04d",errnr);
  printf("\nERROR #%s in \"%s\" %s%s\n%s\n", ERRCODE, US, tmp1, errmsg, tmp2) > "/dev/stderr";
  exit exitcode;
}

# sets SPLIT_DATE_Y, _M, _D + DATE + WEEKDAY
function split_date(_my_date,      _n, _a) {
  if (_my_date ~ /^([0-9][0-9]-[0-9][0-9]-[0-9][0-9]|[0-9][0-9][.][0-9][0-9][.][0-9][0-9])$/) { _my_date="20"_my_date; } # set default Jahrhundert "20"
  if (_my_date ~ /^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|[0-9][0-9][0-9][0-9][.][0-9][0-9][.][0-9][0-9])$/) { 
    _n=split(_my_date,_a,/[-.]/); if (_n!=3) err(1035, "_my_date = '"_my_date"' split by '-' --> n="_n" parts, but expected 3 !?");
    if (DBG) printf(DBGPFX"After split of _my_date'%s' into '%d' parts --> [%s-%s-%s].\n", _my_date, _n, _a[1], _a[2], _a[3]) > "/dev/stderr";
    #if (length(_a[1]) == 4) sub(/^0/,"",_a[1]);
    #if (length(_a[2]) == 2) sub(/^0/,"",_a[2]);
    SPLIT_DATE_Y=_a[1] + 0; SPLIT_DATE_M=_a[2] + 0; SPLIT_DATE_D=_a[3] + 0;
    if (DBG) printf(DBGPFX"After split of _my_date'%s' --> [%s-%s-%s] --> SPLIT_DATE_Y '%s', SPLIT_DATE_M '%s', SPLIT_DATE_D '%s'.\n", _my_date, _a[1], _a[2], _a[3], SPLIT_DATE_Y, SPLIT_DATE_M, SPLIT_DATE_D) > "/dev/stderr";
    if (SPLIT_DATE_Y > CURRENT_YEAR || SPLIT_DATE_Y < 0) err(1036, "_my_date = '"_my_date"' --> SPLIT_DATE_Y '"SPLIT_DATE_Y"'. Must be YEAR value between 0 and "CURRENT_YEAR".");
    if (SPLIT_DATE_M > 12 || SPLIT_DATE_M < 0) err(1037, "_my_date = '"_my_date"' --> SPLIT_DATE_M '"SPLIT_DATE_M"'. Must be MONTH value between 0 and 12.");
    if (SPLIT_DATE_D > 31 || SPLIT_DATE_M < 0) err(1038, "_my_date = '"_my_date"' --> SPLIT_DATE_D '"SPLIT_DATE_D"'. Must be DAY value between 0 and 31.");

    DATE = sprintf("%04d-%02d-%02d", SPLIT_DATE_Y, SPLIT_DATE_M, SPLIT_DATE_D); # reassmble SPLIT_DATE
    WEEKDAY  = strftime("%a", DATE);
    if (DBG) printf(DBGPFX"split_date(): DATE = '"DATE"', WEEKDAY='"WEEKDAY"'") > "/dev/stderr";
  } else err(1039, "_my_date = '"_my_date"', does not seem to match a DATE format (0000-00-00 | 00-00-00) !?");
}

# sets SPLIT_TIME_H, _M + TIME
function split_time(_my_time, _n, _a) {
  if      (_my_time ~ /^[0-9][0-9]$/) { SPLIT_TIME_H=_my_time; sub(/^0/,"",SPLIT_TIME_H); SPLIT_TIME_M="-"; }
  else if (_my_time ~ /^[0-9][0-9]:[0-9][0-9]$/) { 
    _n=split(_my_time,_a,/[:]/); if (_n!=2) err(1022, "_my_time = '"_my_time"' split by ':' --> n="_n" parts, but expected 2 !?");
    if (DBG) printf(DBGPFX"After split of _my_time'%s' --> [%s:%s].\n", _my_time, _a[1], _a[2]) > "/dev/stderr";
    if (length(_a[1]) == 2) sub(/^0/,"",_a[1]);
    if (length(_a[2]) == 2) sub(/^0/,"",_a[2]);
    SPLIT_TIME_H=_a[1] + 0; SPLIT_TIME_M=_a[2] + 0;
    if (DBG) printf(DBGPFX"After split of _my_time'%s' AND removal of leading '0' --> [%s:%s] --> SPLIT_TIME_H '%s', SPLIT_TIME_M '%s'.\n", _my_time, _a[1], _a[2], SPLIT_TIME_H, SPLIT_TIME_M) > "/dev/stderr";
    if (SPLIT_TIME_H > 23 || SPLIT_TIME_H < 0) err(1024, "_my_time = '"_my_time"' --> SPLIT_TIME_H '"SPLIT_TIME_H"'. Must be HOUR value between 0 and 23.");
    if (SPLIT_TIME_M > 59 || SPLIT_TIME_M < 0) err(1026, "_my_time = '"_my_time"' --> SPLIT_TIME_M '"SPLIT_TIME_M"'. Must be MINUTE value between 0 and 59.");
    TIME = sprintf("%02d%02d", SPLIT_TIME_H, SPLIT_TIME_M);
  } else err(1023, "_my_time = '"_my_time"', does not seem to match a TIME format (00 | 00:00) !?");
}

function extract_str(res, what) {
  gsub(/^.*[(<]"/, "", res); # FOR LINES LIKE:  var cellTextSender = document.createTextNode("m6")
  gsub(/^[[:space:]]*"/, "", res);     # FOR LINES LIKE:  cellFormatLink.href = "/?getFile=Blaze_et_les_Monster_Machines_21.11.08_07-00_m6_30_TVOON_DE.mpg.mp4.otrkey"
  if (DBG) printf(DBGPFX"[%s] #%s: --> '%s': '%s'",STATE, FNR, what, res) > "/dev/stderr";
  gsub(/"[)>].*$/, "", res); # FOR LINES LIKE:  var cellTextSender = document.createTextNode("m6")
  gsub(/"[[:space:]]*$/, "", res);     # FOR LINES LIKE:  cellFormatLink.href = "/?getFile=Blaze_et_les_Monster_Machines_21.11.08_07-00_m6_30_TVOON_DE.mpg.mp4.otrkey"
  if (DBG) printf("--> '%s'!\n", res) > "/dev/stderr";
  return res;
}

function sprint_arr(arr, name) {
  tmp_str=""
  i=1;
  for(key in arr){
     if (tmp_str=="") sep=""; else sep="\n";
     tmp_str=sprintf("%s%s%s[%d/%s: \"%s\"] = '%s'", tmp_str,sep,name, i,length(arr),key, arr[key])
     i++;
  }
  return tmp_str;
}

function expected_state(exp_state) {
  if (STATE != exp_state) err(1000, sprintf(DBGPFX"STATE not "exp_state", but "STATE".\nsender = \"%s\"\ntitle = \"%s\"\ndate = \"%s\"\nurl = \"%s\"\n%s\n", sender, title, date, url, sprint_arr(urls,"urls")) );
}

function new_state(the_new_state, comment) {
  if (comment != "") comment=" ("comment")";
  if (DBG) printf(DBGPFX"[%s] --> new STATE '%s'%s\n",STATE, the_new_state, comment) > "/dev/stderr";
  STATE = the_new_state;
}

function select_quality(_res) {
  if (length(RES_BY_RECORDING_AND_QUALITY[_res]) == 0) err(1004, "No entry RES_BY_RECORDING_AND_QUALITY["_res"] found !? (length="(length(RES_BY_RECORDING_AND_QUALITY[_res]))")");

  if ("HQ"     in RES_BY_RECORDING_AND_QUALITY[_res]) { return "HQ"; }
  if ("MP4"    in RES_BY_RECORDING_AND_QUALITY[_res]) { return "MP4"; }
  if ("DivX"   in RES_BY_RECORDING_AND_QUALITY[_res]) { return "DivX"; }
  if ("HD"     in RES_BY_RECORDING_AND_QUALITY[_res]) { return "HD"; }
  if ("AC3"    in RES_BY_RECORDING_AND_QUALITY[_res]) { return "AC3"; }

  err(1001, DBGPFX"RES_BY_RECORDING_AND_QUALITY["_res"]:\n"sprint_arr(RES_BY_RECORDING_AND_QUALITY[_res],"RES_BY_RECORDING_AND_QUALITY["_res"]"));
}

# So, 07.11.21 07:05 --> "2021-11-07\t0705\tSun"
# Sets DATE (2021-12-24), TIME (0844), WEEKDAY (Sun)
function otr_date_to_str(_timestamp) {
  if (DBG) printf(DBGPFX"otr_date_to_str( timestamp = '%s' )\n", _timestamp) > "/dev/stderr";
  _n=split(_timestamp,_a,/[ ]/); if (_n!=3) err(1005, "date+timestamp = '"_timestamp"' split by ' ' --> n="_n" parts, but expected 3 !?");
  switch (_a[1]) {
    case "So,": WEEKDAY="Sun"; break;
    case "Mo,": WEEKDAY="Mon"; break;
    case "Di,": WEEKDAY="Tue"; break;
    case "Mi,": WEEKDAY="Wed"; break;
    case "Do,": WEEKDAY="Thu"; break;
    case "Fr,": WEEKDAY="Fri"; break;
    case "Sa,": WEEKDAY="Sam"; break;
  }
  _n=split(_a[2],_b,/[.]/); if (_n!=3) err(1006, "date '"_a[2]"' split by '.' --> n="_n" parts, but expected 3 !?");
  DATE = "20" _b[3] "-" _b[2] "-" _b[1];

  _n=split(_a[3],_c,/[:]/); if (_n!=2) err(1007, "time '"_a[3]"' split by ':' --> n="_n" parts, but expected 2 !?");
  TIME = _c[1] _c[2];

  return DATE "\t" TIME "\t" WEEKDAY;
}

########################################################################################################
# SEARCHES API-RESULTS !
#
# EXAMPLE:
# https://otr.datenkeller.net/?jdlAPI&suche=Bares&sender=zdf&details&account=<LOGIN-USER-NAME>&apikey=<URL-ENCODED-API-KEY>
#
# 1='Bares_fuer_Rares_23.10.31_10-35_zdfneo_55_TVOON_DE.mpg.mp4.otrkey'
# 2='166078486'  === filesize
# 3='0'  === ???
#
function do_search(_filename,_filesize,    _suffix,_quality,_duration,_channel,_time,_date,_weekday,_title,  _n,_a,_n2,_b,_timestamp_str,_recording) {
  if (DBG) printf(DBGPFX" #%s: 1='%s', 2='%s', 3='%s', 4='%s'\n",FNR, $1, $2, $3, $4) > "/dev/stderr";

  _filename = $1;
  _filesize = $2;

  # SPLIT $1 into: _title _date _time _channel _duration _suffix
  # EXAMPLE: Bares_fuer_Rares_23.10.30_19-20_zdfneo_55_TVOON_DE.mpg.mp4.otrkey

  _n=split(_filename,_a,/[_]/); if (_n<7) err(1034, "_filename = '"_filename"' split by '_' --> n="_n" parts, but expected at least 7 !?");

  # extract _suffix:
  _suffix=_a[_n];
  if (sub(/[.]otrkey$/,"",_suffix) == 0) err(1031, "_suffix='"_suffix"' _filename='"_filename"'")
  if (sub(/^DE[.]/,"",_suffix) == 0) err(1003, "_suffix='"_suffix"', _filename='"_filename"'") 
  # check _suffix ++ determine _quality
  switch (tolower(_suffix)) {
    case "mpg.hd.ac3": _quality="AC3"; break;
    case "mpg.hd.avi": _quality="HD"; break;
    case "mpg.hq.avi": _quality="HQ"; break;
    case "mpg.avi":    _quality="DivX"; break;
    case "mpg.mp4":    _quality="MP4"; break;
    default: err(1032, "UNKNOWN SUFFIX ("_suffix"). _filename'"_filename"'");
  }
  if (DEEPDBG) printf(ALLOWED_DATES_ARRDBGPFX" --> _suffix='%s', _quality='%s', _filename='%s'\n", _suffix, _quality, _filename) > "/dev/stderr";

  #_a[_n-1] == "TVOON"

  _duration=_a[_n-2];
  if (_duration !~ /^[0-9][0-9]*$/) err(1013, "_filename'"_filename"', _n="_n", _duration='"_duration"'")
  if (DEEPDBG) printf(DBGPFX" --> _duration='%s'\n", _duration) > "/dev/stderr";

  _channel=_a[_n-3];
  if (_channel == "") err(1012)
  #if (_channel !~ /^[A-Z0-9]*$/) err(1034, "_filename'"_filename"', _n="_n", _duration='"_duration"'")
  if (DEEPDBG) printf(DBGPFX" --> _channel='%s'\n", _channel) > "/dev/stderr";

  _time=_a[_n-4];
  if (_time == "") err(1010)
  if (sub(/[-]/,":",_time) != 1) err(1041, "_time='"_time"' _filename'"_filename"'") # converge _time to standard format HH:MM
  split_time(_time); _time=TIME;

  _date=_a[_n-5];
  if (_date == "") err(1011)
  split_date(_date); _date=DATE; _weekday=WEEKDAY;

  # reconstruct title with remaining parts:
  _title="";
  for (_i = 1; _i <= _n-6; _i++) _title = _title _a[_i];
  if (_title == "") err(1014)

  # print result of split:
  if (DBG) printf(DBGPFX"\t--> _suffix='%s' _quality='%s', _duration='%s', _channel='%s', _time='%s', _date='%s', _weekday='%s'\n"DBGPFX"\t    _title='%s'\n", _suffix, _quality, _duration, _channel, _time, _date, _weekday, _title) > "/dev/stderr";

  _timestamp_str = _date "_" _time "_" _weekday;

  #### NOW CHECK MATCH:
  # IMPORTANT: Through simple lookup associative array in awk GROWS ! (but value is '' ;)) --> len(..) grows !
  #            But as we only start the lookup if the length was > 0 to begin with, it's OK !

  if (length(ALLOWED_DATES_ARR) > 0 && ALLOWED_DATES_ARR[_date] != 1) {
    if (DBG) printf(DBGPFX"_date='%s' len(ALLOWED_DATES_ARR)='%d'(grows,IGNORE!) ALLOWED_DATES_ARR[_date]='%s' --> '%s'\n", _date, length(ALLOWED_DATES_ARR), ALLOWED_DATES_ARR[_date], (_date in ALLOWED_DATES_ARR) ) > "/dev/stderr";
    if (DBG) printf(DBGPFX" --> Date '" _date "' (from '" _timestamp_str "') not within requested range!\n") > "/dev/stderr";
    return;
  }

  if (length(ALLOWED_WEEKDAYS_ARR) > 0 && ALLOWED_WEEKDAYS_ARR[tolower(_weekday)] != 1) {
    if (DBG) printf(DBGPFX"_weekday='%s' len(ALLOWED_WEEKDAYS_ARR)='%d'(grows,IGNORE!) ALLOWED_WEEKDAYS_ARR[_weekday]='%s' --> '%s'\n", tolower(_weekday), length(ALLOWED_WEEKDAYS_ARR), ALLOWED_WEEKDAYS_ARR[tolower(_weekday)], (tolower(_weekday) in ALLOWED_WEEKDAYS_ARR) ) > "/dev/stderr";
    if (DBG) printf(DBGPFX" --> Weekday '" _weekday "' (from '" _timestamp_str "') not within requested range!\n") > "/dev/stderr";
    return;
  }

  if (length(ALLOWED_TIMES_ARR) > 0 && ALLOWED_TIMES_ARR[_time] != 1) {
    if (DBG) printf(DBGPFX"_time='%s' len(ALLOWED_TIMES_ARR)='%d'(grows,IGNORE!) ALLOWED_TIMES_ARR[_time]='%s' --> '%s'\n", _time, length(ALLOWED_TIMES_ARR), ALLOWED_TIMES_ARR[_time], (_time in ALLOWED_TIMES_ARR) ) > "/dev/stderr";
    if (DBG) printf(DBGPFX" --> Time '" _time "' (from '" _timestamp_str "') not within requested range!\n") > "/dev/stderr";
    return;
  }

  if (length(ALLOWED_CHANNELS_ARR) > 0 && ALLOWED_CHANNELS_ARR[_channel] != 1) {
    if (DBG) printf(DBGPFX"sender/channel='%s' len(ALLOWED_CHANNELS_ARR)='%d'(grows,IGNORE!) ALLOWED_CHANNELS_ARR[_channel]='%s' --> '%s'\n", _channel, length(ALLOWED_CHANNELS_ARR), ALLOWED_CHANNELS_ARR[_channel], (_channel in ALLOWED_CHANNELS_ARR) ) > "/dev/stderr";
    if (DBG) printf(DBGPFX" --> sender/channel '" _channel "' not within requested range!\n") > "/dev/stderr";
    return;
  }

  if (length(ALLOWED_DURATIONS_ARR) > 0 && ALLOWED_DURATIONS_ARR[_duration] != 1) {
    if (DBG) printf(DBGPFX"_duration='%s' len(ALLOWED_DURATIONS_ARR)='%d'(grows,IGNORE!) ALLOWED_DURATIONS_ARR[_duration]='%s' --> '%s'\n", _duration, length(ALLOWED_DURATIONS_ARR), ALLOWED_DURATIONS_ARR[_duration], (_duration in ALLOWED_DURATIONS_ARR) ) > "/dev/stderr";
    if (DBG) printf(DBGPFX" --> Duration '" _duration "' not within requested range!\n") > "/dev/stderr";
    return;
  }

  _recording = sprintf("%s_%s_%s", _timestamp_str, _duration, _channel);
  if (_quality in RES_BY_RECORDING_AND_QUALITY[_recording]) err(1008, "Duplicate recording '"_recording"' in quality '"_quality"'. This should not be. Please verify!")
  if (DBG) printf(DBGPFX"\t--> FOUND RES[%s][%s] = '%s'\n", _recording, _quality, _filename) > "/dev/stderr";
  RES_BY_RECORDING_AND_QUALITY[_recording][_quality] = _filename;
}



########################################################################################################
# DBG: MAIN-LOOP| [0] #75: 1='</script><font color', 2='"green"><b>Premium Download</b></font><br/>High Speed Download startet.. <br><input type', 3='"text" id'
# DBG: MAIN-LOOP| [0] #76: 1='<a class', 2='"piwik_download" href', 3='"https://cluster.lastverteiler.net/87f6b97d7684678fe04fbc5c421a3a9d/Start_the_fck_up_21.11.17_01-40_zdfneo_30_TVOON_DE.mpg.HQ.avi.otrkey">Download Link</a><br/>'
#
# state 0 -- initial state
# state 1 -- new "Premium Download"
# state 2 -- new "Download URL"
#
# state should go: 0 -> 1 -> 0
#
function do_get() {
  if (DBG) printf(DBGPFX" [%s] #%s: 1='%s', 2='%s', 3='%s'\n",STATE, FNR, $1, $2, $3) > "/dev/stderr";

  # Everything by $1 and NOT by 'STATE' to detect malformated files !
  switch ($1 $2) {
    ### STATE 0:
    case "</script><font color\"green\"><b>Premium Download</b></font><br/>High Speed Download startet.. <br><input type": expected_state(0);
      download_URL="";
      new_state(1, "new 'Premium Download' Link found."); break;
    ### STATE 1:
    case "<a class\"piwik_download\" href":  expected_state(1); download_URL=extract_str($3, "download_URL");
      printf("%s\n", download_URL);
  }
}


function set_ALLOWED_DURATIONS_ARR() {
  _from=""; _til="";
  if (TILL_DURATION == "") {
    if (FROM_DURATION == "") return;
    else { _til=999; _from=FROM_DURATION + 0; }
  } else {
    _til=TILL_DURATION + 0;
    if (FROM_DURATION == "") _from=0;
    else _from=FROM_DURATION + 0;
  }
  if (DBG) printf(DBGPFX" set_ALLOWED_DURATIONS_ARR(): _from: '%s', _til: '%s'\n", _from, _til) > "/dev/stderr";
  if (_from > _til) err(1028, "FILTER_DURATION_FROM() _from '" _from "' > '" _til " _til ?!");
  if (! (_from <= _til)) err(1029, "FILTER_DURATION_FROM() _from '" _from "' NOT <= '" _til "' _til ?!");
  for (_dd = _from; _dd <= _til; _dd++) ALLOWED_DURATIONS_ARR[_dd] = 1;
}


# Also covers case where         FROM_TIME 23:00  and  TILL_TIME 02:00      /or/     FROM_TIME 22:40  and  TILL_TIME 22:30 !!!
function set_ALLOWED_TIMES_ARR() {
  if (TILL_TIME == "") {
    if (FROM_TIME == "") return # NEITHER FROM_TIME nor TILL_TIME
    else { TILL_TIME_H=23; TILL_TIME_M=59; } # FROM_TIME without TILL_TIME
  } else { 
    if (FROM_TIME == "") { FROM_TIME_H=0; FROM_TIME_M=0; } # TILL_TIME without FROM_TIME
  }
  if (TILL_TIME_H < FROM_TIME_H) TILL_TIME_H += 24;
  else if (TILL_TIME_H == FROM_TIME_H && TILL_TIME_M != "-" && TILL_TIME_M < FROM_TIME_M) TILL_TIME_H += 24;
  for (_hh = FROM_TIME_H; _hh <= TILL_TIME_H; _hh++) {
    _start_m=-1; _end_m=-1;
    if (_hh == FROM_TIME_H) if (FROM_TIME_M == "-") { _start_m=0; _end_m=59; } else _start_m=FROM_TIME_M;
    if (_hh == TILL_TIME_H) if (TILL_TIME_M == "-") { if (_start_m == -1) _start_m=0; _end_m=59; } else _end_m=TILL_TIME_M;
    if (_start_m == -1) _start_m=0;
    if (_end_m == -1) _end_m=59;
    if (DBG) printf(DBGPFX" set_ALLOWED_TIMES_ARR(): FROM_TIME: '%s:%s', TILL_TIME: '%s:%s' :: _hh:'%s', _start_m:'%s', _end_m:'%s'\n", FROM_TIME_H, FROM_TIME_M, TILL_TIME_H, TILL_TIME_M, _hh, _start_m, _end_m) > "/dev/stderr";
    for (_mm = _start_m; _mm <= _end_m; _mm++) {
      if (_hh > 23) _tmp_str=sprintf( "%02d%02d", (_hh-24), _mm);
      else _tmp_str=sprintf( "%02d%02d", _hh, _mm);
      if (DBG) printf(DBGPFX" set_ALLOWED_TIMES_ARR(): FROM_TIME: '%s:%s', TILL_TIME: '%s:%s' :: _hh:'%s', _start_m:'%s', _end_m:'%s' --> '%s'\n", FROM_TIME_H, FROM_TIME_M, TILL_TIME_H, TILL_TIME_M, _hh, _start_m, _end_m, _tmp_str) > "/dev/stderr";
      ALLOWED_TIMES_ARR[_tmp_str] = 1;
    }
  }
}


# expects: FROM_DATE, FROM_DATE_Y, FROM_DATE_M, FROM_DATE_D
# and      TILL_DATE, TILL_DATE_Y, TILL_DATE_M, TILL_DATE_D
# to be set
function set_ALLOWED_DATES_ARR(   _yyyy, _mm, _dd, _start_m, _end_m, _start_d, _end_d, _tmp_str) {
  if (TILL_DATE == "") {
    # NEITHER FROM_DATE nor TILL_DATE:
    if (FROM_DATE == "") return
    else { TILL_DATE_Y=CURRENT_YEAR; TILL_DATE_M=CURRENT_MONTH; TILL_DATE_D=CURRENT_DAY;
           TILL_DATE=sprintf("%04d-%02d-%02d", TILL_DATE_Y, TILL_DATE_M, TILL_DATE_D); } # FROM_DATE without TILL_DATE
  } else {
    # TILL_DATE without FROM_DATE:
    if (FROM_DATE == "") { FROM_DATE_Y=1970; FROM_DATE_M=1; FROM_DATE_D=1;
                           FROM_DATE=sprintf("%04d-%02d-%02d", FROM_DATE_Y, FROM_DATE_M, FROM_DATE_D); } # FROM_DATE without FROM_DATE
  }
  if (DBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): Before LOOP: FROM_DATE: '%s-%s-%s', TILL_DATE: '%s-%s-%s'\n", FROM_DATE_Y, FROM_DATE_M, FROM_DATE_D, TILL_DATE_Y, TILL_DATE_M, TILL_DATE_D) > "/dev/stderr";
  for (_yyyy = FROM_DATE_Y; _yyyy <= TILL_DATE_Y; _yyyy++) {
    if (_yyyy == FROM_DATE_Y) _start_m = FROM_DATE_M; else _start_m = 1;
    if (_yyyy == TILL_DATE_Y) _end_m   = TILL_DATE_M; else _end_m   = 12;
    if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): _yyyy='%s' -> _start_m='%s', _end_m='%s'\n", _yyyy, _start_m, _end_m) > "/dev/stderr";
    for (_mm = _start_m; _mm <= _end_m; _mm++) {
      if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): 1_BEFORE _dd-loop -- _yyyy='%s' _mm='%s' _end_m='%s' _start_d='%s' _end_d='%s'\n", _yyyy, _mm, _end_m, _start_d, _end_d) > "/dev/stderr";
      if (_yyyy == FROM_DATE_Y && _mm == FROM_DATE_M) _start_d = FROM_DATE_D; else _start_d = 1;
      if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): 2_BEFORE _dd-loop -- _yyyy='%s' _mm='%s' _end_m='%s' _start_d='%s' _end_d='%s'\n", _yyyy, _mm, _end_m, _start_d, _end_d) > "/dev/stderr";
      if (_yyyy == TILL_DATE_Y && _mm == TILL_DATE_M) _end_d   = TILL_DATE_D; else "cal "_mm" "_yyyy"|xargs -n1|tac"|getline _end_d;
      if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): _yyyy='%s' _mm='%s' -> _start_d='%s', _end_d='%s'\n", _yyyy, _mm, _start_d, _end_d) > "/dev/stderr";
      for (_dd = _start_d; _dd <= _end_d; _dd++) {
        _tmp_str=sprintf( "%04d-%02d-%02d", _yyyy, _mm, _dd);
        if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): FROM_DATE: '%s-%s-%s', TILL_DATE: '%s-%s-%s' :: _start_m:'%s', _end_m:'%s', _start_d:'%s', _end_d:'%s' --> '%s'\n", FROM_DATE_Y, FROM_DATE_M, FROM_DATE_D, TILL_DATE_Y, TILL_DATE_M, TILL_DATE_D, _start_m, _end_m, _start_d, _end_d, _tmp_str) > "/dev/stderr";
        ALLOWED_DATES_ARR[_tmp_str] = 1;
      }
      if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): AFTER _dd-loop -- _yyyy='%s' _mm='%s' _end_m='%s'\n", _yyyy, _mm, _end_m) > "/dev/stderr";
    }
    if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): AFTER _mm-loop -- _yyyy='%s' _mm='%s' _end_m='%s'\n", _yyyy, _mm, _end_m) > "/dev/stderr";
  }
  if (DEEPDBG) printf(DBGPFX" set_ALLOWED_DATES_ARR(): AFTER _yyyy-loop -- _yyyy='%s' _mm='%s' _end_m='%s'\n", _yyyy, _mm, _end_m) > "/dev/stderr";
}



### INIT:
BEGIN {
  #DBG=1;
  #DEEPDBG=1; # only set manually

  US="my-otr.awk"

  DBGPFX_DEFAULT="DBG: "
  DBGPFX=DBGPFX_DEFAULT"BEGIN| "

  STATE=0;
  split("", RES_BY_RECORDING_AND_QUALITY);

  if (ARGC == 0) usage();
  if (DBG) printf(DBGPFX"BEFORE ARGV-LOOP: ARGC='%d'\n", ARGC) > "/dev/stderr";
  WHAT="";
  for (i in ARGV) {
    arg = ARGV[i];
    if (DBG) printf(DBGPFX"WITHIN ARGV-LOOP: [%d] arg = '%s'\n", i, arg) > "/dev/stderr";
    switch (arg) {
      case "help": usage(); break;
      case "search": FS=";"; WHAT="search"; delete ARGV[i]; break;
      case "get": FS="="; WHAT="get"; delete ARGV[i]; break;
      }
  }
  if (WHAT == "") err(1020, "No <COMMAND> specified. Call with 'help'.");
  if (DBG) printf(DBGPFX"AFTER ARGV-LOOP: ARGC='%d'\n", ARGC) > "/dev/stderr";
  if (DBG) printf(DBGPFX"AFTER ARGV-LOOP: WHAT = '%s'\n", WHAT) > "/dev/stderr";

  CURRENT_YEAR=strftime("%Y")+0;
  CURRENT_MONTH=strftime("%m")+0;
  CURRENT_DAY=strftime("%d")+0;
  if (DBG) printf(DBGPFX"CURRENT_YEAR='%s', CURRENT_MONTH='%s', CURRENT_DAY='%s'\n", CURRENT_YEAR, CURRENT_MONTH, CURRENT_DAY) > "/dev/stderr";

  if (WHAT != "search") {
  # WHAT != "search":

    if (CHANNELS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE CHANNELS '%s'.\n", CHANNELS) > "/dev/stderr";

    if (DESCR != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE DESCR '%s'.\n", DESCR) > "/dev/stderr";

    if (DURATIONS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE DURATIONS '%s'.\n", DURATIONS) > "/dev/stderr";
    if (FROM_DURATION != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE FROM_DURATION '%s'.\n", FROM_DURATION) > "/dev/stderr";
    if (TILL_DURATION != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TILL_DURATION '%s'.\n", TILL_DURATION) > "/dev/stderr";

    if (TIMES != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TIMES '%s'.\n", TIMES) > "/dev/stderr";
    if (FROM_TIME != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE FROM_TIME '%s'.\n", FROM_TIME) > "/dev/stderr";
    if (TILL_TIME != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TILL_TIME '%s'.\n", TILL_TIME) > "/dev/stderr";

    if (FROM_DATE != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE FROM_DATE '%s'.\n", FROM_DATE) > "/dev/stderr";
    if (TILL_DATE != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TILL_DATE '%s'.\n", TILL_DATE) > "/dev/stderr";

    if (WEEKDAYS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE WEEKDAYS '%s'.\n", WEEKDAYS) > "/dev/stderr";

  } else {
  # WHAT == "search":

    ### DESCRIPTION:
    if (DESCR != "") if (DBG) printf(DBGPFX"Will search for DESCRIPTION '%s'.\n", DESCR) > "/dev/stderr";

    ### CHANNELS:
    split("",ALLOWED_CHANNELS_ARR);
    if (CHANNELS != "") {
      split(tolower(CHANNELS),_tmp_arr,/[	]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_CHANNELS_ARR[ _tmp_arr[_i] ] = 1; }
      if (DBG) printf(DBGPFX"Will search %s CHANNELS '%s'.\n", length(ALLOWED_CHANNELS_ARR), CHANNELS) > "/dev/stderr";
    }
    if (DBG) printf(DBGPFX"ALLOWED_CHANNELS_ARR() length:%s = \n%s<<<<<<<<<<<\n", length(ALLOWED_CHANNELS_ARR), sprint_arr( ALLOWED_CHANNELS_ARR )) > "/dev/stderr";

    ### DURATIONS:
    split("", ALLOWED_DURATIONS_ARR);
    if (DURATIONS != "") {
      split(tolower(DURATIONS),_tmp_arr,/[ ]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_DURATIONS_ARR[_tmp_arr[_i]+0]=1; } # <<< ensure that we store only NUMBERS ! ( + 0 forces awk to type it as int ! )
      if (DBG) printf(DBGPFX"Will search for %s DURATIONS '%s'.\n", length(ALLOWED_DURATIONS_ARR), DURATIONS) > "/dev/stderr";
    }
    if (FROM_DURATION != "") if (DBG) printf(DBGPFX"Will search for FROM_DURATION '%s'.\n", FROM_DURATION) > "/dev/stderr";
    if (TILL_DURATION != "") if (DBG) printf(DBGPFX"Will search for TILL_DURATION '%s'.\n", TILL_DURATION) > "/dev/stderr";
    set_ALLOWED_DURATIONS_ARR()
    if (DEEPDBG) printf(DBGPFX"ALLOWED_DURATIONS_ARR() length:%s.\n%s<<<<<<<<<<<\n", length(ALLOWED_DURATIONS_ARR), sprint_arr( ALLOWED_DURATIONS_ARR )) > "/dev/stderr";

    ### TIMES:
    split("", ALLOWED_TIMES_ARR);
    if (TIMES != "") {
      if (DBG) printf(DBGPFX"TIMES = '%s'\n", TIMES) > "/dev/stderr";
      split(tolower(TIMES),_tmp_arr,/[ ]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { split_time(_tmp_arr[_i]); ALLOWED_TIMES_ARR[ sprintf("%02d%02d", SPLIT_TIME_H, SPLIT_TIME_M) ] = 1; }
      if (DBG) printf(DBGPFX"Will search for %s TIMES '%s'.\n", length(ALLOWED_TIMES_ARR), TIMES) > "/dev/stderr";
    }
    if (FROM_TIME != "") {
      split_time(FROM_TIME);
      FROM_TIME_H = SPLIT_TIME_H; FROM_TIME_M = SPLIT_TIME_M;
      if (DBG) printf(DBGPFX"Will search FROM_TIME '%s' (>=) [%s:%s].\n", FROM_TIME, FROM_TIME_H, FROM_TIME_M) > "/dev/stderr";
    }
    if (TILL_TIME != "") {
      split_time(TILL_TIME);
      TILL_TIME_H = SPLIT_TIME_H; TILL_TIME_M = SPLIT_TIME_M;
      if (DBG) printf(DBGPFX"Will search TILL_TIME '%s' (<=) [%s:%s].\n", TILL_TIME, TILL_TIME_H, TILL_TIME_M) > "/dev/stderr";
    }
    set_ALLOWED_TIMES_ARR()
    if (DEEPDBG) printf(DBGPFX"ALLOWED_TIMES_ARR() length:%s = \n%s<<<<<<<<<<<\n", length(ALLOWED_TIMES_ARR), sprint_arr( ALLOWED_TIMES_ARR )) > "/dev/stderr";

    ### DATES:
    split("", ALLOWED_DATES_ARR);
    if (FROM_DATE != "") {
      split_date(FROM_DATE);
      FROM_DATE_Y = SPLIT_DATE_Y; FROM_DATE_M = SPLIT_DATE_M; FROM_DATE_D = SPLIT_DATE_D;
      if (DBG) printf(DBGPFX"Will search FROM_DATE '%s' (>=) [%s-%s-%s].\n", FROM_DATE, FROM_DATE_Y, FROM_DATE_M, FROM_DATE_D) > "/dev/stderr";
    }
    if (TILL_DATE != "") {
      split_date(TILL_DATE);
      TILL_DATE_Y = SPLIT_DATE_Y; TILL_DATE_M = SPLIT_DATE_M; TILL_DATE_D = SPLIT_DATE_D;
      if (DBG) printf(DBGPFX"Will search TILL_DATE '%s' (<=) [%s-%s-%s].\n", TILL_DATE, TILL_DATE_Y, TILL_DATE_M, TILL_DATE_D) > "/dev/stderr";
    }
    set_ALLOWED_DATES_ARR()
    if (DEEPDBG) printf(DBGPFX"ALLOWED_DATES_ARR() length:%s = \n%s<<<<<<<<<<<\n", length(ALLOWED_DATES_ARR), sprint_arr( ALLOWED_DATES_ARR )) > "/dev/stderr";

    ### WEEKDAYS:
    split("",ALLOWED_WEEKDAYS_ARR);
    if (WEEKDAYS != "") {
      split(tolower(WEEKDAYS),_tmp_arr,/[ ]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_WEEKDAYS_ARR[ _tmp_arr[_i] ] = 1; }
      if (DBG) printf(DBGPFX"Will search %s WEEKDAYS '%s'.\n", length(ALLOWED_WEEKDAYS_ARR), WEEKDAYS) > "/dev/stderr";
    }
    if (DEEPDBG) printf(DBGPFX"ALLOWED_WEEKDAYS_ARR() length:%s = \n%s<<<<<<<<<<<\n", length(ALLOWED_WEEKDAYS_ARR), sprint_arr( ALLOWED_WEEKDAYS_ARR )) > "/dev/stderr";
  }

  DBGPFX=DBGPFX_DEFAULT"MAIN-LOOP| "
};
{
  if (DBG) printf(DBGPFX"START-OF-NEW-CYCLE:\n") > "/dev/stderr";
  # Ignore EMPTY lines:
  if ($1 == "") next;

  # Trim LEADING spaces
  gsub(/^[ \t]+/, "", $1)
  gsub(/^[ \t]+/, "", $2)
  # Trim TRAILING spaces
  gsub(/[ \t]+$/, "", $1)
  gsub(/[ \t]+$/, "", $2)

  switch (WHAT) {
    case "search": do_search(); break;
    case "get": do_get(); break;
    default: err(1021, "Invalid WHAT '" WHAT "'");
  }
  if (DBG) printf(DBGPFX"END-OF-NEW-CYCLE:\n") > "/dev/stderr";
}
END{
  DBGPFX=DBGPFX_DEFAULT"RESULT| "
  switch (WHAT) {
    case "search": # select proper quality:
      if (DBG) if (length(RES_BY_RECORDING_AND_QUALITY)==0) printf(DBGPFX"READ "FNR" RESULTS. NO MATCHING RECORDING FOUND.\n") > "/dev/stderr";
               else if (DBG) printf(DBGPFX"READ "FNR" RESULTS. SELECTING PROPER QUALITY FOR EACH OF "(length(RES_BY_RECORDING_AND_QUALITY))" RECORDINGS:\n") > "/dev/stderr";
      _n = asorti( RES_BY_RECORDING_AND_QUALITY, sorted_recordings ); # sort by INDEX --> by _recording --into--> sorted_recordings!
      for (_i=1; _i<=_n; _i++) {
        _recording = sorted_recordings[_i];
        if (DBG) printf(DBGPFX"["_recording"]: length="length(RES_BY_RECORDING_AND_QUALITY[_recording])".\n") > "/dev/stderr";
        quality = select_quality( _recording );
        if (DBG) printf(DBGPFX"["_recording"] --> selected quality '"quality"'\n") > "/dev/stderr";
        if (quality == "") err(1015, "_recording='"_recording"'")
        if (quality == "IGNORED") { new_state(0, "Ignored row without sufficient quality.\n"sprint_arr(urls,"urls")); break; }
        if (! quality in RES_BY_RECORDING_AND_QUALITY[_recording]) err(1016, "quality='"quality"'\n"sprint_arr(RES_BY_RECORDING_AND_QUALITY[_recording],"RES_BY_RECORDING_AND_QUALITY["_recording"]"))
        _res = RES_BY_RECORDING_AND_QUALITY[_recording][quality]
        if (_res == "") err(1017)
        if (DBG) printf(DBGPFX"["_recording"] --> PRINTING '"_res"'\n") > "/dev/stderr";
        print(_res);
      };
      break;
    case "get": break;
    default: err(1002, "Invalid WHAT '" WHAT "'");
  }

  if (DBG) printf(DBGPFX"done.\n") > "/dev/stderr"
  printf ("") > "/dev/stderr" ### <<< without these 2 lines I got an return-code of 141 from awk !?!??!?!
  close("/dev/stderr");       ### <<< without these 2 lines I got an return-code of 141 from awk !?!??!?!
  #print ("exit 0") > "/dev/stderr"
  exit 0
}
