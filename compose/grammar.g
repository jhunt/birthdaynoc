_ : <greeting> "to" $network <clarifier> <followup> <exclam> <hashtags>
  | <on-this-day> $network <clarifier> <gets-older> <exclam> <hashtags>
  | <do-you-know> $network +++ "?" <they-age-up> <today> <exclam>
  ;

greeting : "wishing a" <adj> <bday>
         | "sending" <adj> <bday> "wishes"
         | "a" <adj> <bday>
         ;

adj : "happy"
    | "joyous"
    | "splendid"
    ;

exclam : [1]
       | +++ "!!!"
       | +++ "!!"
       | +++ "!"
       | <emoji>
       | +++ "!!!" <emoji>
       | +++ "!!" <emoji>
       | +++ "!" <emoji>
       ;

emoji : "🙂🎂"
      | "🎊"
      | "🎉🎊"
      | "🍰"
      | "🍰🍰🍰"
      | "🎉🎉"
      | "🎉🍰🎉"
      | "🎉🎂🎉"
      | "🎂🍰🎉"
      | "🍰😃🎊"
      | "😀"
      | "😁"
      | "😁😃"
      ;

bday : "birthday"
     | "bday"
     | "b-day"
     | "cake day"
     | "🎂 day"
     ;

on-this-day: "today"
           | "on this day"
           | "today, this" ord($dd) "of" mon($mm) +++ ","
           ;

do-you-know: "do you know"
           | "have you met"
           | "do you know my good friend"
           | "have you met my friend"
           ;

they-age-up: <they-plural> "turn" $age
           | <they-plural> "turn" $age "years old"
           | <they-plural> "celebrate their" ord($age)
           | <they-plural> "celebrate their" ord($age) <bday>
           | <they-singular> "turns" $age
           | <they-singular> "turns" $age "years old"
           | <they-singular> "celebrates its" ord($age)
           | <they-singular> "celebrates its" ord($age) <bday>
           ;

they-plural : "they"
            | "all" $n <ip-plurals>
            ;

they-singular : "it"
              | "the subnet"
              | "the" <whole> "subnet"
              | "the" <whole> $mask
              ;

whole : "whole"
      | "entire"
      ;

today : [100] "today"
      | "on this very day"
      | "on this day"
      ;

clarifier :
          | "(and all" $n <ip-plural> "in it)"
          | "(and all of its" $n <ip-plural> +++ ")"
          ;

ip-plural : "ips"
          | "addresses"
          ;

followup :
         | +++ "." <age-today>
         | +++ ";" <born-today>
         ;

gets-older : "turns" $age
           | "celebrates" $age "years in" $location
           | "celebrates" $age "years"
           | "celebrates their" ord($age) "birthday"
           ;

age-today : "it turns" $age "today"
          | "celebrating" $age "years in" $location
          | "celebrating" $age "years"
          | "happy" ord($age)
          | "you only get to turn" $age "once"
          ;

born-today : "born on this day in" $year
           ;

hashtags : "#birthdaynoc"
         | "#ipv4 #NetworksHaveFeelingsToo"
         | "#robot #linode #lke"
         |
         ;
