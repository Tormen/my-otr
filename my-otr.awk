#!/usr/local/bin/awk

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

function split_time(_my_time) {
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
  } else err(1023, "_my_time = '"_my_time"', does not seem to match a TIME format (00 | 00:00) !?");
}

function extract_str(res, what) {
  gsub(/^.*[(<]"/, "", res); # FOR LINES LIKE:  var cellTextSender = document.createTextNode("m6")
  gsub(/^[[:space:]]*"/, "", res);     # FOR LINES LIKE:  cellFormatLink.href = "/?getFile=Blaze_et_les_Monster_Machines_21.11.08_07-00_m6_30_TVOON_DE.mpg.mp4.otrkey"
  if (DBG) printf(DBGPFX"[%s] #%s: --> '%s': '%s'",state, FNR, what, res) > "/dev/stderr";
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
  if (state != exp_state) err(1000, sprintf(DBGPFX"state not "exp_state", but "state".\nsender = \"%s\"\ntitle = \"%s\"\ndate = \"%s\"\nurl = \"%s\"\n%s\n", sender, title, date, url, sprint_arr(urls,"urls")) );
}

function new_state(the_new_state, comment) {
  if (comment != "") comment=" ("comment")";
  if (DBG) printf(DBGPFX"[%s] --> new state '%s'%s\n",state, the_new_state, comment) > "/dev/stderr";
  state = the_new_state;
}

function select_quality() {
  if (length(urls) == 0) err(1004, "No urls found !? (length(urls)="(length(urls))")");

  if ("HQ"     in urls) { return "HQ"; }
  if ("mp4"    in urls) { return "mp4"; }
  if ("divx"   in urls) { return "divx"; }
  if ("HD"     in urls) { return "HD"; }
  if ("HD_ac3" in urls) { return "IGNORED"; }

  err(1001, DBGPFX"urls seem too empty:\n"sprint_arr(urls,"urls"));
}

# So, 07.11.21 07:05 --> "2021-11-07\t0705\tSun"
# Sets DATE (2021-12-24), TIME (0844), DAY (Sun)
function otr_date_to_str(_timestamp) {
  if (DBG) printf(DBGPFX"otr_date_to_str( timestamp = '%s' )\n", _timestamp) > "/dev/stderr";
  _n=split(_timestamp,_a,/[ ]/); if (_n!=3) err(1005, "date+timestamp = '"_timestamp"' split by ' ' --> n="_n" parts, but expected 3 !?");
  switch (_a[1]) {
    case "So,": DAY="Sun"; break;
    case "Mo,": DAY="Mon"; break;
    case "Di,": DAY="Tue"; break;
    case "Mi,": DAY="Wed"; break;
    case "Do,": DAY="Thu"; break;
    case "Fr,": DAY="Fri"; break;
    case "Sa,": DAY="Sam"; break;
  }
  _n=split(_a[2],_b,/[.]/); if (_n!=3) err(1006, "date '"_a[2]"' split by '.' --> n="_n" parts, but expected 3 !?");
  DATE = "20" _b[3] "-" _b[2] "-" _b[1];

  _n=split(_a[3],_c,/[:]/); if (_n!=2) err(1007, "time '"_a[3]"' split by ':' --> n="_n" parts, but expected 2 !?");
  TIME = _c[1] _c[2];

  return DATE "\t" TIME "\t" DAY;
}

########################################################################################################
# state 0 -- initial state
# state 1 -- new row (with search result)
# state 2 -- new tv entry found
# state 3 -- new tv url found
#
# state should go: 0 -> 1 -> 2 ( -> 3 -> 2 )+ -> 0
#
function do_search() {
  if (DBG) printf(DBGPFX"[%s] #%s: 1='%s', 2='%s', 3='%s'\n",state, FNR, $1, $2, $3) > "/dev/stderr";

  # Everything by $1 and NOT by 'state' to detect malformated files !
  switch ($1) {
    ### STATE 0:
    case "var row": if ($2 != "document.createElement(\"tr\")") next; expected_state(0);
      date=""; sender=""; duration=""; title=""; url=""; split("", urls); quality="";
      new_state(1, "new row --> RESET"); break;
    ### STATE 1:
    case "var cellTextSender":  expected_state(1); sender=extract_str($2, "sender");
      new_state(2, "sender:'"sender"'"); break;
    ### STATE 2:
    case "var cellTextSendung": expected_state(2); title=extract_str($2, "title"); break;
    case "var cellTextDatum":   expected_state(2); date=extract_str($2, "date"); break;

    case "var cellTextDauer":   expected_state(2); duration=extract_str($2, "duration")+0; break;

    case "cellFormatLink":      expected_state(2);
      new_state(3, "title:'"title"' date:'"date"' duration:'"duration"'"); break;
    ### STATE 3: -- to parse download link, if done, we'll go back to state 2!
    case "cellFormatLink.href": expected_state(3); url=extract_str($2, "url")"="extract_str($3); break;
    case "cellFormatLink.appendChild(cellImgFormatHDac3)": expected_state(3); new="HD_ac3"; urls[new]=url; break;
    case "cellFormatLink.appendChild(cellImgFormat)":      expected_state(3); new="divx"; urls[new]=url; break;
    case "cellFormatLink.appendChild(cellImgFormatHDavi)": expected_state(3); new="HD"; urls[new]=url; break;
    case "cellFormatLink.appendChild(cellImgFormatHQavi)": expected_state(3); new="HQ"; urls[new]=url; break;
    case "cellFormatLink.appendChild(cellImgFormatmp4)":   expected_state(3); new="mp4"; urls[new]=url; break;
    case "cellFormat.appendChild(cellFormatLink)":         expected_state(3);
      if (url == "") err(1018, "new='"new"'")
      if (new == "") err(1019, "url='"url"'")
      new_state(2, "new quality found: '"new"' '"url"'"); break;
    ### END: STATE -1 or STATE 1 or STATE 2:
    case "tblBody.appendChild(row)":
      if (state == 1) { new_state(0, "Ignored row without otr entry."); break; };
      if (date == "Datum") { new_state(0, "Ignored HEADER row."); break; };
      expected_state(2);

      timestamp_str = otr_date_to_str(date);
      if (timestamp_str == "") err(1025);
      # IMPORTANT: Through simple lookup associative array in awk GROWS ! (but value is '' ;)) --> len(..) grows !
      #            But as we only start the lookup if the length was > 0 to begin with, it's OK !
      if (length(ALLOWED_TIMES_ARR) > 0 && ALLOWED_TIMES_ARR[TIME] != 1) {
        if (DBG) printf(DBGPFX"TIME='%s' len(ALLOWED_TIMES_ARR)='%d'(grows,IGNORE!) ALLOWED_TIMES_ARR[TIME]='%s' --> '%s'\n", TIME, length(ALLOWED_TIMES_ARR), ALLOWED_TIMES_ARR[TIME], (TIME in ALLOWED_TIMES_ARR) ) > "/dev/stderr";
        new_state(0, "Time '" TIME "' (from '" timestamp_str "') not within requested range!"); break;
      }

      if (length(ALLOWED_DAYS_ARR) > 0 && ALLOWED_DAYS_ARR[tolower(DAY)] != 1) {
        if (DBG) printf(DBGPFX"DAY='%s' len(ALLOWED_DAYS_ARR)='%d'(grows,IGNORE!) ALLOWED_DAYS_ARR[DAY]='%s' --> '%s'\n", tolower(DAY), length(ALLOWED_DAYS_ARR), ALLOWED_DAYS_ARR[tolower(DAY)], (tolower(DAY) in ALLOWED_DAYS_ARR) ) > "/dev/stderr";
        new_state(0, "Weekday '" DAY "' (from '" timestamp_str "') not within requested range!"); break;
      }

      if (date == "") err(1011)

      if (duration == "") err(1013)
      if (length(ALLOWED_DURATIONS_ARR) > 0 && ALLOWED_DURATIONS_ARR[duration] != 1) {
        if (DBG) printf(DBGPFX"duration='%s' len(ALLOWED_DURATIONS_ARR)='%d'(grows,IGNORE!) ALLOWED_DURATIONS_ARR[duration]='%s' --> '%s'\n", duration, length(ALLOWED_DURATIONS_ARR), ALLOWED_DURATIONS_ARR[duration], (duration in ALLOWED_DURATIONS_ARR) ) > "/dev/stderr";
        new_state(0, "Duration '" duration "' not within requested range!"); break;
      }

      if (sender == "") err(1012)
      if (length(ALLOWED_CHANNELS_ARR) > 0 && ALLOWED_CHANNELS_ARR[sender] != 1) { 
        if (DBG) printf(DBGPFX"sender/channel='%s' len(ALLOWED_CHANNELS_ARR)='%d'(grows,IGNORE!) ALLOWED_CHANNELS_ARR[sender]='%s' --> '%s'\n", sender, length(ALLOWED_CHANNELS_ARR), ALLOWED_CHANNELS_ARR[sender], (sender in ALLOWED_CHANNELS_ARR) ) > "/dev/stderr";
        new_state(0, "sender/chanel '" sender "' not within requested range!"); break;
      }

      if (title == "") err(1014)

      quality = select_quality();
      if (quality == "") err(1015, "date='"date"' duration='"duration"' sender='"sender"' title='"title"'")
      if (quality == "IGNORED") { new_state(0, "Ignored row without sufficient quality.\n"sprint_arr(urls,"urls")); break; }
      if (! quality in urls) err(1016, "quality='"quality"'\n"sprint_arr(urls,"urls"))
      url = urls[quality];
      if (url == "") err(1017)

      if (DBG) printf(DBGPFX"RESULT-LINE: %s\t%s\t%s\t%s\t%s\t%s\n", timestamp_str, duration, sender, quality, title, url) > "/dev/stderr";
      printf("%s\t%s\t%s\t%s\t%s\t%s\n", timestamp_str, duration, sender, quality, title, url);
      new_state(0, "Done with entry!"); break;
  };

  ### STATE 3:
  # cellFormatLink = document.createElement("a")
  # cellFormatLink.href = "/?getFile=The_Blacklist_21.06.20_19-25_6plus_50_TVOON_DE.mpg.HD.avi.otrkey"
  # cellFormatLink.setAttribute("target", "_blank")
  #cellFormatLink.appendChild(cellImgFormatHDavi)
  #cellFormat.appendChild(cellFormatLink)
  #cellFormatLink = document.createElement("a")
  # cellFormatLink.href = "/?getFile=The_Blacklist_21.06.20_19-25_6plus_50_TVOON_DE.mpg.avi.otrkey"
  # cellFormatLink.setAttribute("target", "_blank")
  #cellFormatLink.appendChild(cellImgFormat)
  #cellFormat.appendChild(cellFormatLink)
  return 0
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
  if (DBG) printf(DBGPFX"[%s] #%s: 1='%s', 2='%s', 3='%s'\n",state, FNR, $1, $2, $3) > "/dev/stderr";

  # Everything by $1 and NOT by 'state' to detect malformated files !
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
  if (TIL_DURATION == "") {
    if (FROM_DURATION == "") return;
    else { _til=999; _from=FROM_DURATION + 0; }
  } else {
    _til=TIL_DURATION + 0;
    if (FROM_DURATION == "") _from=0;
    else _from=FROM_DURATION + 0;
  }
  if (DBG) printf(DBGPFX" set_ALLOWED_DURATIONS_ARR(): _from: '%s', _til: '%s'\n", _from, _til) > "/dev/stderr";
  if (_from > _til) err(1028, "FILTER_DURATION_FROM() _from '" _from "' > '" _til " _til ?!");
  if (! (_from <= _til)) err(1029, "FILTER_DURATION_FROM() _from '" _from "' NOT <= '" _til "' _til ?!");
  for (_dd = _from; _dd <= _til; _dd++) ALLOWED_DURATIONS_ARR[_dd] = 1;
}


# Also covers case where         FROM_TIME 23:00  and  TIL_TIME 02:00      /or/     FROM_TIME 22:40  and  TIL_TIME 22:30 !!!
function set_ALLOWED_TIMES_ARR() {
  if (TIL_TIME == "") {
    if (FROM_TIME == "") return # NEITHER FROM_TIME nor TIL_TIME
    else { TIL_TIME_H=23; TIL_TIME_M=59; } # FROM_TIME without TIL_TIME
  } else { 
    if (FROM_TIME == "") { FROM_TIME_H=0; FROM_TIME_M=0; } # TIL_TIME without FROM_TIME
  }
  if (TIL_TIME_H < FROM_TIME_H) TIL_TIME_H += 24;
  else if (TIL_TIME_H == FROM_TIME_H && TIL_TIME_M != "-" && TIL_TIME_M < FROM_TIME_M) TIL_TIME_H += 24;
  for (_hh = FROM_TIME_H; _hh <= TIL_TIME_H; _hh++) {
    _start_m=-1; _end_m=-1;
    if (_hh == FROM_TIME_H) if (FROM_TIME_M == "-") { _start_m=0; _end_m=59; } else _start_m=FROM_TIME_M;
    if (_hh == TIL_TIME_H) if (TIL_TIME_M == "-") { if (_start_m == -1) _start_m=0; _end_m=59; } else _end_m=TIL_TIME_M;
    if (_start_m == -1) _start_m=0;
    if (_end_m == -1) _end_m=59;
    if (DBG) printf(DBGPFX" set_ALLOWED_TIMES_ARR(): FROM_TIME: '%s:%s', TIL_TIME: '%s:%s' :: _hh:'%s', _start_m:'%s', _end_m:'%s'\n", FROM_TIME_H, FROM_TIME_M, TIL_TIME_H, TIL_TIME_M, _hh, _start_m, _end_m) > "/dev/stderr";
    for (_mm = _start_m; _mm <= _end_m; _mm++) {
      if (_hh > 23) _tmp_str=sprintf( "%02d%02d", (_hh-24), _mm);
      else _tmp_str=sprintf( "%02d%02d", _hh, _mm);
      if (DBG) printf(DBGPFX" set_ALLOWED_TIMES_ARR(): FROM_TIME: '%s:%s', TIL_TIME: '%s:%s' :: _hh:'%s', _start_m:'%s', _end_m:'%s' --> '%s'\n", FROM_TIME_H, FROM_TIME_M, TIL_TIME_H, TIL_TIME_M, _hh, _start_m, _end_m, _tmp_str) > "/dev/stderr";
      ALLOWED_TIMES_ARR[_tmp_str] = 1;
    }
  }
}


### INIT:
BEGIN {
  #DBG=1;
  FS="=";

  US="my-otr.awk"

  DBGPFX_DEFAULT="DBG: "
  DBGPFX=DBGPFX_DEFAULT"BEGIN| "

  state=0;
  #split("", urls);

  if (ARGC == 0) usage();
  if (DBG) printf(DBGPFX"BEFORE ARGV-LOOP: ARGC='%d'\n", ARGC) > "/dev/stderr";
  WHAT="";
  for (i in ARGV) {
    arg = ARGV[i];
    if (DBG) printf(DBGPFX"WITHIN ARGV-LOOP: [%d] arg = '%s'\n", i, arg) > "/dev/stderr";
    switch (arg) {
      case "help": usage(); break;
      case "search": WHAT="search"; delete ARGV[i]; break;
      case "get": WHAT="get"; delete ARGV[i]; break;
    }
  }
  if (WHAT == "") err(1020, "No <COMMAND> specified. Call with 'help'.");
  if (DBG) printf(DBGPFX"AFTER ARGV-LOOP: ARGC='%d'\n", ARGC) > "/dev/stderr";
  if (DBG) printf(DBGPFX"AFTER ARGV-LOOP: WHAT = '%s'\n", WHAT) > "/dev/stderr";

  if (WHAT != "search") {
  # WHAT != "search":

    if (CHANNELS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE CHANNELS '%s'.\n", CHANNELS) > "/dev/stderr";

    if (DESCR != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE DESCR '%s'.\n", DESCR) > "/dev/stderr";

    if (DURATIONS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE DURATIONS '%s'.\n", DURATIONS) > "/dev/stderr";
    if (FROM_DURATION != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE FROM_DURATION '%s'.\n", FROM_DURATION) > "/dev/stderr";
    if (TIL_DURATION != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TIL_DURATION '%s'.\n", TIL_DURATION) > "/dev/stderr";

    if (TIMES != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TIMES '%s'.\n", TIMES) > "/dev/stderr";
    if (FROM_TIME != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE FROM_TIME '%s'.\n", FROM_TIME) > "/dev/stderr";
    if (TIL_TIME != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE TIL_TIME '%s'.\n", TIL_TIME) > "/dev/stderr";

    if (DAYS != "") if (DBG) printf(DBGPFX"<COMMAND> is NOT 'search' --> Will IGNORE DAYS '%s'.\n", DAYS) > "/dev/stderr";

  } else {
  # WHAT == "search":

    split("",ALLOWED_CHANNELS_ARR);
    if (CHANNELS != "") {
      split(tolower(CHANNELS),_tmp_arr,/[	]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_CHANNELS_ARR[ _tmp_arr[_i] ] = 1; }
      if (DBG) printf(DBGPFX"Will search %s CHANNELS '%s'.\n", length(ALLOWED_CHANNELS_ARR), CHANNELS) > "/dev/stderr";
    }
    if (DBG) printf(DBGPFX"ALLOWED_CHANNELS_ARR() = \n%s<<<<<<<<<<<\n", sprint_arr( ALLOWED_CHANNELS_ARR )) > "/dev/stderr";

    if (DESCR != "") if (DBG) printf(DBGPFX"Will search for DESCRIPTION '%s'.\n", DESCR) > "/dev/stderr";

    split("", ALLOWED_DURATIONS_ARR);
    if (DURATIONS != "") {
      split(tolower(DURATIONS),_tmp_arr,/[ ]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_DURATIONS_ARR[_tmp_arr[_i]+0]=1; } # <<< ensure that we store only NUMBERS ! ( + 0 forces awk to type it as int ! )
      if (DBG) printf(DBGPFX"Will search for %s DURATIONS '%s'.\n", length(ALLOWED_DURATIONS_ARR), DURATIONS) > "/dev/stderr";
    }
    if (FROM_DURATION != "") if (DBG) printf(DBGPFX"Will search for FROM_DURATION '%s'.\n", FROM_DURATION) > "/dev/stderr";
    if (TIL_DURATION != "") if (DBG) printf(DBGPFX"Will search for TIL_DURATION '%s'.\n", TIL_DURATION) > "/dev/stderr";
    set_ALLOWED_DURATIONS_ARR()
    if (DBG) printf(DBGPFX"ALLOWED_DURATIONS_ARR() = \n%s<<<<<<<<<<<\n", sprint_arr( ALLOWED_DURATIONS_ARR )) > "/dev/stderr";

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
    if (TIL_TIME != "") {
      split_time(TIL_TIME);
      TIL_TIME_H = SPLIT_TIME_H; TIL_TIME_M = SPLIT_TIME_M;
      if (DBG) printf(DBGPFX"Will search TIL_TIME '%s' (<=) [%s:%s].\n", TIL_TIME, TIL_TIME_H, TIL_TIME_M) > "/dev/stderr";
    }
    set_ALLOWED_TIMES_ARR()
    if (DBG) printf(DBGPFX"ALLOWED_TIMES_ARR() = \n%s<<<<<<<<<<<\n", sprint_arr( ALLOWED_TIMES_ARR )) > "/dev/stderr";

    split("",ALLOWED_DAYS_ARR);
    if (DAYS != "") {
      split(tolower(DAYS),_tmp_arr,/[ ]/); #if (DBG) printf(DBGPFX"_tmp_arr = [%s]\n%s<<<<<<<<<<<<<<", length(_tmp_arr), sprint_arr( _tmp_arr)) > "/dev/stderr";
      for (_i in _tmp_arr) { ALLOWED_DAYS_ARR[ _tmp_arr[_i] ] = 1; }
      if (DBG) printf(DBGPFX"Will search %s DAYS '%s'.\n", length(ALLOWED_DAYS_ARR), DAYS) > "/dev/stderr";
    }
    if (DBG) printf(DBGPFX"ALLOWED_DAYS_ARR() = \n%s<<<<<<<<<<<\n", sprint_arr( ALLOWED_DAYS_ARR )) > "/dev/stderr";
  }

  DBGPFX=DBGPFX_DEFAULT"MAIN-LOOP| "
};
{
  if (DBG) printf(DBGPFX"START-OF-NEW-CYCLE:") > "/dev/stderr";
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
  if (DBG) printf(DBGPFX"END-OF-NEW-CYCLE:") > "/dev/stderr";
}
END{
  DBGPFX=DBGPFX_DEFAULT"RESULT| "
  if (DBG) printf(DBGPFX"done.") > "/dev/stderr"
  printf ("") > "/dev/stderr" ### <<< without these 2 lines I got an return-code of 141 from awk !?!??!?!
  close("/dev/stderr");       ### <<< without these 2 lines I got an return-code of 141 from awk !?!??!?!
  #print ("exit 0") > "/dev/stderr"
  exit 0
}
