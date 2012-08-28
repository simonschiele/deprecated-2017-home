#!/usr/bin/awk -f 

BEGIN {
    if ( ARGC >= 2 ) {
        for (i = 1; i < ARGC; i++) {
            if (i == ARGC - 1) {
                if (! system("[ -e "ARGV[i]" ]")) {
                    file=1 
                }
            }
            if (!file) {
                nodes[i] = ARGV[i]
                delete ARGV[i]
            }
        }
    }
    json_block=0
    invalid=0
}
{
    for (i = 1; i <= length; i++) 
    {
        character=substr($0, i, 1)
        
        if (first_char == "" && character != " ") {
            first_char=character
            break
        } else {
            if ( character == "{" || character == "[" ) { 
                hierarchy++
                matched=1 
            }

            if ( character == "}" || character == "]" ) {
                hierarchy--
            }
        }
        
        if (character == "'") {
            if (singlequote == 1)
                singlequote=0
            else
                singlequote=1
        }
        
        if (character == "\"") {
            if (doublequote == 1)
                doublequote=0
            else
                doublequote=1
        }
        
        if ((singlequote == 1 || doublequote == 1 || character != " ") && (hierarchy != 0 || character != ",") && hierarchy != -1){
            json[json_block]=json[json_block] character
        }

        if (matched == 1 && hierarchy == 0 || (hierarchy == 0 && character == ",")) {
            json_block++
            matched=0
        }

        if (hierarchy == -1 && character != " ") {
            last_char=character
        }
    }
} 
END {
    if (hierarchy != -1 || singlequote != 0 || doublequote != 0)
        invalid=1
    
    if (invalid == 0 && ((first_char == "{" && last_char == "}") || (first_char == "[" || last_char == "]"))) {
        if (nodes[1]) {
            for (node in json) {
                split(node,splitted,":")
                print splitted
                #for (xxx in splitted) {
                #    print xxx
                    #json_sorted[key] = json_sorted[key] xxx
                #}
            }
        } else {
            for (node in json) {
                if (json[node] != ",") {
                    print json[node]
                }
            }
        }
    } else {
        print "json invalid" > "/dev/stderr"
        exit 1
    }
}
