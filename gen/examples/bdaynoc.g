_ : <greeting> "to" $subnet <clarifier> <followup> <hashtags>
  ;

greeting : "wishing a" <adj> <bday>
         | "sending" <adj> <bday> "wishes"
         | "a" <adj> <bday>
         ;

adj : "happy"
    | "joyous"
    | "splendid"
    ;

bday : "birthday"
     | "bday"
     | "b-day"
     | "cake day"
     | "🎂 day"
     ;

clarifier :
          | "(and all" $n <ip-plural> "in it)"
          | "(and all of its" $n <ip-plural> ")"
          ;

ip-plural : "ips"
          | "addresses"
          ;

followup :
         | "." <age-today>
         | ";" <born-today>
         ;

age-today : "it turns" $years "today!"
          | "celebrating" $years "years in" $location
          | "celebrating" $years "years"
          | "happy" ord($years)
          | "you only get to turn" $years "once!"
          ;

born-today : "born on this day in" $year
           ;

hashtags : "#birthdaynoc"
         | "#ipv4 #NetworksHaveFeelingsToo"
         |
         ;
