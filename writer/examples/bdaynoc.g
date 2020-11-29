_ : <greeting> "to" $network <clarifier> <followup> <hashtags>
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

age-today : "it turns" $age "today!"
          | "celebrating" $age "years in" $location
          | "celebrating" $age "years"
          | "happy" ord($age)
          | "you only get to turn" $age "once!"
          ;

born-today : "born on this day in" $year
           ;

hashtags : "#birthdaynoc"
         | "#ipv4 #NetworksHaveFeelingsToo"
         | "#robot #linode #lke"
         |
         ;
