#  ____________
# |            |
# |    TALK    |
# |____________|
# 
# Language website: https://Talk-reference-guide--theangryepicbanana.repl.co
# 
# Version 1.0.3
# ==== New Stuff ====
# - Changed how a few things work.
# ===================
# 
#   ______________________________________
#  /  Some cool language that I'm making, \
#  \  so idk why you're interested in it. /
#  /  While you're here, could you tell   \
#  \  other people about this pls?        /
#   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# (yes I know that my code is messy, deal with it)

use MONKEY-SEE-NO-EVAL;

my @Extensions = [];

sub call-method(\value, Str $method-name) {
    return -> *@args {(gather {take Pair.new(.gist, $_) if .^name ~~ "Method" for value.^methods}.Hash){$method-name}(value, |@args)}
}

sub Parse-Extension(\file, $ext is copy) {
    my @r;
    my $Pattern = ($ext ~~ /^^Find':'\s*(.+?)[^^Replace':']/)[0].Str;
    my $Replace = ($ext ~~ /^^Replace':'\s?(\N+)/)[0].Str;
    $Pattern ~~ s:m:g/\n\h*//;
    EVAL 'file ~~ s:g/' ~ $Pattern ~ '/' ~ $Replace ~ '/';
}



my $file = slurp @*ARGS[0];

$file ~~ s:g/\"':('(<-[\)]>+?)')'/$0.Str+\"/;
$file ~~ s:g/':('(<-[\)]>+?)')'\"/\"+$0.Str/;
$file ~~ s:g/':('(<-[\)]>+?)')'/\"+$0.Str+\"/;

my $STR;
$file ~~ s:m:g/(\"<(<-[\"]>+?)>\")/({$STR = $0.Str.encode(qq<UTF-8>).perl}.decode.Str)/;
$file ~~ s:m:g/(\W)(\'<(<-[\']>+?)>\')/$0\"$1\"/;

$file ~~ s:g/^^\s*(\S+?)\h+means\h+(\N+?)\n/, $0 => $1/;
$file ~~ s:m:g/(dictionary\s*?\()\s+?/$0/;

$file ~~ s:g/('(')', '/$0/;
$file ~~ s:g/','(')')$$/$0/;
$file ~~ s:g/\s*\n\s*')'/\)/;

$file ~~ s:g/'#'\[.+?\] | '-/'.+?'-\\'//;

$file ~~ s:g/\s[And|then]\s/\n/;

my $code = "";

my \true = True;
my \false = False;
my \empty = Nil;
my \newline = "\n";

multi sub infix:<+>($s1, Str $s2) {
    return $s1 ~ $s2;
}

multi sub infix:<*>(Str $s1, Int $times) {
    my $out-str = "";
    for ^$times {
        $out-str += $s1;
    }
    return $out-str;
}

multi sub infix:</>(Str $s1, Str $s2) {
    return $s1.split: $s2;
}

multi sub prefix:<each-in>(%hash) {
    my $out = "";
    for %hash -> $kv {
        $out += $kv.key + ": " + $kv.value.perl + "\n";
    }
    return $out.chop;
}

multi sub infix:<as>(%hash, Str $s) {
    my $ns = %hash.perl;
    $ns ~~ s:g/':'(\S+?)'('(<-[\)]>)')'/{$s.subst("#k", $0).subst("#v", $1)}/;
    return $ns;
}

multi sub postcircumfix:<[ ]>(Str $s, @get) {
    return $s.substr: @get;
}

sub list(*@elements) {
    return @elements;
}

sub dictionary(*@pairs) {
    my %h;
    for @pairs -> $pair {
        %h{$pair.key} = $pair.value;
    }
    return %h;
}

#my %var-list;

for $file.lines -> $line {
    given $line {
        
        # #:Extend with my-custom-extension.sme
        
        when /^'#:'Extend\swith\s(\N+?)$/ {
            push @Extensions, slurp "$0"
        }
        
        # make var be 1
        
        when /^\s*make\s(.+?)\sbe\s(\N+?)$/ {
            $code += "my \\$0 = my \$$0 = $1;\n";
        }
        
        # now var is 2
        # -----OR-----
        # var is now 2
        
        when /^\s*now\s(\S+?)\sis\s(\N+?)$/ | /^(\S+?)\sis\snow\s(\N+?)$/ {
            $code += "$0 = $1;\n\n";
        }
        
        # $func [$a, $b]
        # -----OR-----
        # method func takes $a, $b
        
        when /^\s*['$'|method\s](\S+?)$/ | /^\s*['$'|method\s](\S+?)\s?['['(<-[\]]>+?)']'|takes\s?(<-[\n]>+?)]$/ {
            with $1 {
                $code += "sub $0\($1) \{\n";
            } else {
                $code += "sub $0 \{\n";
            }
        }
        
        # &func2 [$a, $b]
        # -----OR-----
        # and func2 takes $a, $b
        
        when /^\s*['&'|also\s](\S+?)$/ | /^\s*['&'|also\s](\S+?)\s?['['(<-[\]]>+?)']'|takes\s?(<-[\n]>+?)]$/ {
            with $1 {
                $code += "\}\nsub $0\($1) \{\n";
            } else {
                $code += "\}\nsub $0 \{\n";
            }
        }
        
        # end
        
        when /^\s*end$/ {
            $code += "\}\n";
        }
        
        # a is 1
        
        #when /^\s*(\S+?)\s+is\s+(\N+?)$/ {
        #    $code += "$0 => $1,\n";
        #}
        
        # if true
        
        when /^\s*if\s+(\N+?)$/ {
            $code += "if $0 \{\n";
        }
        
        # also if true
        
        when /^\s*[also\sif|elsif]\s+(\N+?)$/ {
            $code += "\} elsif $0 \{\n";
        }
        
        # otherwise
        
        when /^\s*[else|otherwise]$/ {
            $code += "\} else \{\n";
        }
        
        # given some-value
        
        when /^\s*given\s+(\N+)$/ {
            $code += "given $0 \{\n#";
        }
        
        # when value then stuff
        # -----OR-----
        # when value
        #   stuff
        
        when /^\s*when\s+(\N+)/ {
            $code += "}\nwhen $0 \{\n"
        }
        
        # default then stuff then end
        # -----OR-----
        # default
        #   stuff
        # end
        
        when /^\s*default\s*$/ {
            $code += "}\ndefault \{\n";
        }
        
        # loop num times as i
        
        when /^\s*loop\s+(\w+?)\s+times\s+as\s+(\w+?)$/ {
            $code += "for 0..$0 -> \$$1 \{my \\$1 = \$$1;\n";
        }
        
        # loop through dict as k, v
        
        when /^\s*loop\s+through\s+(\w+?|'['<-[\]]>+?']'|'{'<-[\}\n]>+?'}'|'('<-[\)\n]>+?')')\s+as\s+(\w+)[', '|','](\w+?)$/ {
            $code += "for $0 -> \@GET_KV \{my \\$1 = \@GET_KV[0];my \\$2 = \@GET_KV[1];\n";
        }
        
        # loop through list as i
        
        when /^\s*loop\s+through\s+(\w+?|'['<-[\]]>+?']'|'{'<-[\}\n]>+?'}'|'('<-[\)\n]>+?')')\s+as\s+(\w+)$/ {
            $code += "for $0 -> \$$1 \{my \\$1 = \$$1;\n";
        }
        
        # loop from a to b as i
        
        when /^\s*loop\s+from\s+(\S+?)\s+to\s+(\S+?)\s+as\s+(\N+?)$/ {
            $code += "for $0..$1 -> \$$2 \{my \\$2 = \$$2;\n";
        }
        
        # loop k, v through dict
        
        when /^\s*loop\s+(\w+)[', '|','](\w+?)\s+through\s+(\N+?)$/ {
            $code += "for $2 -> \@GET_KV \{my \\$0 = \@GET_KV[0];my \\$1 = \@GET_KV[1];\n";
        }
        
        # loop i through list
        
        when /^\s*loop\s+(\w+?)\s+through\s+(\N+?)$/ {
            $code += "for $1 -> \$$0 \{my \\$0 = \$$0;\n";
        }
        
        # loop while my $i = some-iterator-thing
        # "$" is needed because it's not trying to parse whatever's after "loop while"
        
        when /^\s*loop\s+while\s+(\N+?)$/ {
            $code += "while $0 \{\n";
        }
        
        # loop with some-list
        # Same deal as "loop while"
        
        when /^\s*loop\s+with\s+(\N+?)$/ {
            $code += "for $0 \{\n";
        }
        
        # make myClass
        
        when /^\s*make\s(\N+?)$/ {
            $code += "class $0 \{\n";
        }
        
        # on classMethod [$a, $b]
        
        when /^\s*on\s(\S+?)$/ | /^\s*on\s(\S+?)\s'['(<-[\]]>+?)']'$/ {
            with $1 {
                $code += "method $0\($1) \{\n";
            } else {
                $code += "method $0 \{\n";
            }
        }
        
        # on classMethod takes a, b
        
        when /^\s*on\s(\S+?)\stakes\s(\N+?)$/ {
            my $args = "";
            for $1.split(", ") -> $el {
                $args += "\$$el, ";
            }
            $code += "method $0\(" + $args.chop.chop + "\) \{\n";
        }
        
        # on setup a is p1, b is p2 and then
        
        when /^\s*on\ssetup\s(\N+?)\sand\sdo$/ {
            my $args = "";
            my $set-vars = "";
            for $0.split(", ") -> $el {
                my @kv = $el[4..*].split: " is ";
                $args += "\$@kv[1], ";
                $set-vars += "@kv[0] \=\> \$@kv[1], ";
            }
            $code += "method new\(" + $args.chop.chop + "\) \{self\.bless\(" + $set-vars.chop.chop + "\);\n";
        }
        
        # on setup a is p1, b is p2
        
        when /^\s*on\ssetup\s(\N+?)$/ {
            my $args = "";
            my $set-vars = "";
            for $0.split(", ") -> $el {
                my @kv = $el[4..*].split: " is ";
                $args += "\$@kv[1], ";
                $set-vars += "@kv[0] \=\> \$@kv[1], ";
            }
            $code += "method new\(" + $args.chop.chop + "\) \{self\.bless\(" + $set-vars.chop.chop + "\);\}\n";
        }
        
        # its p is 1
        
        when /^\s*its\s+(\S+?)$/ | /^\s*its\s+(\S+?)\s+is\s+(\N+?)$/ {
            with $1 {
                $code += "has \$\.$0 = $1;\n";
            } else {
                $code += "has \$\.$0;\n";
            }
        }
        
        # it takes p1, p2
        
        when /^\s*it\stakes\s(\N+?)$/ {
            for $0.split(", ") -> $v {
                $code += "has \$\.$v is rw;\n";
            }
        }
        
        default {
            $code += $line.trim ne "" ?? $line + ";\n\n" !! "";
        }
    }
}

$code ~~ s:g/(\( || \[ || \{ || \,)\;/$0/;
$code ~~ s:g/\(\n\n\,/\(/;

for @Extensions -> $ext {
    Parse-Extension $code, $ext;
}



multi sub infix:<is>(Cool $v1, Cool $v2) {
    return $v1 ~~ $v2;
}

multi sub infix:<isnt>(Cool $v1, Cool $v2) {
    return not $v1 ~~ $v2;
}

if @*ARGS[1] {
    if @*ARGS[1] ~~ one <--debug -d> {say $code}
    else {EVAL $code}
}
