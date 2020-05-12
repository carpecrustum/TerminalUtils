#!/usr/local/ActivePerl-5.24/bin/perl
use strict;
use utf8;
use Devel::Symdump;
use Test::More tests => 7;
use Test::MockModule;
use Test::Deep;
use Carp::Assert;
use Carp::Assert::More;

my $module = 'Carpecrustum::TerminalUtils';
use_ok ($module);

package Carpecrustum::TerminalUtilsTest;
use parent 'Carpecrustum::TerminalUtils';

sub set_keystrokes {
    my $self = shift;
    my $array = shift;
    $self->{keystrokes} = [];
    foreach my $keystroke (@$array) {
        push @{$self->{keystrokes}}, $keystroke;
    }
    return;
}

sub get_key {
    my $self = shift;
    my $keystroke = "";
    if (!exists($self->{keystrokes})) {
        $self->{keystrokes} = [];
    }

    if ( scalar( @{$self->{keystrokes}} ) > 0 ) {
        $keystroke = shift( @{$self->{keystrokes}} );
    }
    return $keystroke;
}
     


package main;

run_tests();
# run_tests([&test_title_box, &test_menu]);
exit 0;

sub run_tests {
    ## looks for any function named test_*
    # so that I don't have one long inline flow of test cases
    # and I don't need to remember to call them in a main()
    # of some kind.

    my @function_list =  shift // Devel::Symdump->functions();
    foreach my $function (@function_list) {
        if ( $function =~ /^main::test_/ ) {
            ## no critic
            no strict 'refs';    # violates 'Stricture disabled'
            $function->();
            ## use critic
        }
    }
    done_testing();
}


sub test_sorting {
    return subtest sorting => sub {
        plan tests => 6;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner( 'Orion Township Library' );
       
        my $headings = _headings();
        my $data = _three_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 2, 'Picker returned 2001...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                      Orion Township Library
    Title\N{BLACK UP-POINTING TRIANGLE}                             Author                             Call number
$bar
    2001, A space odyssey              Clarke, Arthur C.                  823
    Imaginary numbers                  McGuire, Seanan                    813.6
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in title order");
 
        my $selected = $term->picker($headings, $data, 'author');
        is( $selected, 2, 'Picker returned 2001...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                      Orion Township Library
    Title                              Author\N{BLACK UP-POINTING TRIANGLE}                            Call number
$bar
    2001, A space odyssey              Clarke, Arthur C.                  823
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    Imaginary numbers                  McGuire, Seanan                    813.6
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in author order");
 
        my $selected = $term->picker($headings, $data, 'call number');
        is( $selected, 1, 'Picker returned Moon...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                      Orion Township Library
    Title                              Author                             Call number\N{BLACK UP-POINTING TRIANGLE}
$bar
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    Imaginary numbers                  McGuire, Seanan                    813.6
    2001, A space odyssey              Clarke, Arthur C.                  823
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in call number order");
 
        
    };
}


sub test_change_sort_column {
    return subtest change_sort_column => sub {
        plan tests => 2;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner("New Column Sorting Test");
       
        my $headings = _headings();
        my $data = _three_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        my @keys = qw( 2 );
        $term->set_keystrokes( \@keys );
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 2, 'Picker returned 2001...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                      New Column Sorting Test
    Title                              Author\N{BLACK UP-POINTING TRIANGLE}                            Call number
$bar
    2001, A space odyssey              Clarke, Arthur C.                  823
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    Imaginary numbers                  McGuire, Seanan                    813.6
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in author order");
 
    };
}


sub test_reverse_sorting {
    return subtest reverse_sorting => sub {
        plan tests => 2;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner("Reverse Sorting Test");
       
        my $headings = _headings();
        my $data = _three_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        my @keys = qw( 2 2 RETURN );
        $term->set_keystrokes( \@keys );
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 3, 'Picker returned Imaginary numbers' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                       Reverse Sorting Test
    Title                              Author\N{BLACK DOWN-POINTING TRIANGLE}                            Call number
$bar
    Imaginary numbers                  McGuire, Seanan                    813.6
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    2001, A space odyssey              Clarke, Arthur C.                  823
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in reverse author order");
 
    };
}


sub test_picker {
    return subtest picker => sub {
        plan tests => 6;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner( 'Lake Agassiz Public Library' );
       
        my $headings = _headings();
        my $data = _three_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 2, 'Picker returned 2001...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                    Lake Agassiz Public Library
    Title\N{BLACK UP-POINTING TRIANGLE}                             Author                             Call number
$bar
    2001, A space odyssey              Clarke, Arthur C.                  823
    Imaginary numbers                  McGuire, Seanan                    813.6
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in title order");
 
        my $selected = $term->picker($headings, $data, 'author');
        is( $selected, 2, 'Picker returned 2001...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                    Lake Agassiz Public Library
    Title                              Author\N{BLACK UP-POINTING TRIANGLE}                            Call number
$bar
    2001, A space odyssey              Clarke, Arthur C.                  823
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    Imaginary numbers                  McGuire, Seanan                    813.6
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in author order");
 
        my $selected = $term->picker($headings, $data, 'call number');
        is( $selected, 1, 'Picker returned Moon...' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                    Lake Agassiz Public Library
    Title                              Author                             Call number\N{BLACK UP-POINTING TRIANGLE}
$bar
    The moon is a harsh mistress       Heinlein, Robert A.                813.54
    Imaginary numbers                  McGuire, Seanan                    813.6
    2001, A space odyssey              Clarke, Arthur C.                  823
TEXT
        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in call number order");
 
        
    };
}


sub test_arrow_down {
    return subtest arrow_down => sub {
        plan tests => 2;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner("Arrow Down Test");
       
        my $headings = _headings();
        my $data = _fifty_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        my @keys = qw( DOWN_ARROW RETURN );
        $term->set_keystrokes( \@keys );
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 51, 'Picker returned 6502 software design' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                          Arrow Down Test
    Title\N{BLACK UP-POINTING TRIANGLE}                             Author                             Call number
$bar
    3-D Starter Kit for Macintosh      Wagstaff, Sean                     006.6 WAGST
    6502 software design               Scanlon, Leo J., 1941-             005.265 6502
    Alone Against Tomorrow             Ellison, Harlan                    SF 813.54 ELLIS
    Analog's Children of the futur     edited by Stanley Schmidt.         SC 813.54 Schmidt
    Between planets;                   Heinlein, Robert A. (Robert An     SF 813.54 Heinlein
    Bid time return                    Matheson, Richard, 1926-2013.      FIC 813.54 Matheson
    Build your own Ajax web applic     Eernisse, Matthew.                 005.434 EERNI
    Calculus :one and several vari     Salas, Saturnino L.                515 SALAS
    Citizen of the galaxy              Heinlein, Robert A. (Robert An     SF 813.54 HEINL
    Coils                              Zelazny, Roger.                    SF 813.54 ZELAZ
    Cryptanalysis for microcompute     Foster, Caxton C., 1929-           652.8 FOSTE
    The defiant agents,                Norton, Andre.                     SF 813.54 Norton
    The Door into Summer               Heinlein, Robert A. (Robert An     SF 813.54 HEINL
    The Door into Summer               Heinlein, Robert A. (Robert An     SF 813.54 HEINL
    Double star                        Heinlein, Robert A. (Robert An     SF 813.54 HEINL
    Effects of enrichment problems     Ouellette, Hugh Francis.           372 Ouellette
    Emergence                          Palmer, David R. 1941-             SF Palmer
    Farmer in the sky                  Heinlein, Robert A. (Robert An     SF HEI
    Father, Son & Co. : my life at     Watson, Thomas J., 1914-1993       338.7 WATSO
    Handbook of mathematical table     Burington, Richard Stevens, 19     REF 510.212 BURIN
    Hellstrom's hive                   Herbert, Frank.                    FIC 813.54 Herbert
    The illearth war                   Donaldson, Stephen R.              FANTASY 813.54 DONAL
    Illusions : the adventures of      Bach, Richard.                     FIC 813.54 Bach
    Ishmael                            Quinn, Daniel.                     FIC 813.54 Quinn
    Jeb Stuart, the last cavalier.     Davis, Burke, 1913-                973.73 BURKE
    Juggling for the complete klut     Cassidy, John                      793.87 Cassidy
    Lord Foul's bane                   Donaldson, Stephen R.              FANTASY 813.54 DONAL
    Lost continents; the Atlantis      De Camp, L. Sprague (Lyon Spra     398.23 DeCAMP
    Managing the software process      Humphrey, Watts S., 1927-          005.1 HUMPH
    Mapping time : the calendar an     Richards, E. G. (Edward Graham     529.3 RICHA
    Microbe hunters                    De Kruif, Paul, 1890-1971.         589.900 DE KRU
    My name is legion                  Zelazny, Roger.                    SF 813.54 Zelazny
    A Name to Conjure With             Aamodt, Donald                     FANTASY 813.54 Aamod
    Odyssey : Pepsi to Apple--a jo     Sculley, John.                     331.7 SCULL
    Old Turtle                         Wood, Douglas, 1951-               E 813.54 WOOD
    Owls in the family.                Mowat, Farley.                     FIC Mowat
    The power that preserves           Donaldson, Stephen R.              FANTASY 813.54 DONAL
    The power that preserves           Donaldson, Stephen R.              FANTASY 813.54 DONAL
    The Pritcher Mass,                 Dickson, Gordon R.                 SF 813.54 Dickson
    Probability and statistical in     Hogg, Robert V.                    519.2 HOGG
    The ship that sailed the time      Edmondson, G. C.                   SF 813.54 Edmondson
    Something of value                 Ruark, Robert Chester, 1915-19     FIC 813.54 Ruark
    Spellsinger : novel                Foster, Alan Dean, 1946-           FANTASY 813.54 FOSTE
TEXT

        add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in title order");
 
    };
}


sub test_paging {
    return subtest paging => sub {
        plan tests => 2;

        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->set_picker_banner("Paging Test");
       
        my $headings = _headings();
        my $data = _fifty_titles();

        my $bar = "\N{BOX DRAWINGS HEAVY HORIZONTAL}" x 100;
        my @keys = ( 'DOWN_ARROW' ) x 53;
        push @keys, 'RETURN';

        $term->set_keystrokes( \@keys );
        my $selected = $term->picker($headings, $data, 'title');
        is( $selected, 44, 'Picker returned Virus!' );

        my @expected = _blank_screen();
        add_to_screen(1, 1, \@expected, <<"TEXT");
                                            Paging Test
    Title\N{BLACK UP-POINTING TRIANGLE}                             Author                             Call number
$bar
    Spellsinger : novel                Foster, Alan Dean, 1946-           FANTASY 813.54 FOSTE
    Steve Jobs : the journey is th     Young, Jeffrey S., 1952-           338.7 YOUNG
    Stranger in a strange land.        Heinlein, Robert A. (Robert An     SF 813.54 HEINL
    Threshold                          Palmer, David R.                   SF 813.54 Palmer
    The time traders                   Norton, Andre.                     SF 813.54 Norton
    A trace of memory                  Laumer, Keith, 1925-               SF 813.54 Laumer
    The Universe between.              Nourse, Alan E. (Alan Edward)      SF 813.52 Nourse
    UNIX in a Nutshell : system V      Gilly, Daniel                      005.432 GILLY
    Up the line.                       Silverberg, Robert.                SF 813.54 SILVE
    Virus! : the secret world of c     Lundell, Allan.                    005.8 LUNDE
    Voyagers in time; twelve stori     Silverberg, Robert.                SC 813.54 Silverberg
    The whole Internet user's guid     Krol, Ed.                          384.3 KROL
    The wounded land                   Donaldson, Stephen R.              FANTASY 813.54 DONAL
    The wounded land                   Donaldson, Stephen R.              FANTASY 813.54 DONAL
TEXT
    add_to_screen(1, 47, \@expected, $bar);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "page is displayed in title order");
    
    };
}


sub _blank_screen {
    my $row = ' ' x 100;
    my @screen = ($row) x 48; 
    return @screen;
}


sub array_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $got = shift;
    my $want = shift;
    my $msg = shift;

    require Test2::Tools::Compare;
    assert_arrayref( $got );
    assert_arrayref( $want );
    return Test2::Tools::Compare::is( $got, $want, $msg );
}

sub margin_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $got = shift;
    my $want = shift;
    my $msg = shift;
    assert_arrayref( $got );
    assert_arrayref( $want );

    my $got_margin = 0;
    my $want_margin = 0;
    foreach my $line (@$want) {
        $line =~ s/ +$//g;
        if ($line =~ /^( +)/) {
            $want_margin = length($1);
            last;
        }
    }

    foreach my $line (@$got) {
        $line =~ s/ +$//g;
        if ($line =~ /^( +)/) {
            $got_margin = length($1);
            last;
        }
    }
    require Test2::Tools::Compare;
    return Test2::Tools::Compare::is( $got_margin, $want_margin, $msg );
}


sub strip_margins {
    my $list_ref = shift;
    my @return_list;

    foreach my $line (@$list_ref) {
        $line =~ s/^ +//;
        $line =~ s/ +$//;
        if (length($line) > 0) {
            push @return_list, $line;
        }
    }
    return @return_list;
}


=head2 add_to_screen

Takes a multi-line string and breaks it on CRLF, using substr
to insert it into the screen array starting at the specified x, y
coordinates.

X and Y coordinates are 1-based.

=cut

sub add_to_screen {
    my $x = shift;
    my $y = shift;
    my $screen_ref = shift;
    my $image = shift;

    my @seg = split( /[\n\r]/, $image );
    
    # convert from 1-based to 0-based
    $x = $x - 1;
    $y = $y - 1;

    foreach my $seg (@seg) {
        my $len = length($seg);
        substr($$screen_ref[$y], $x, $len) = $seg if ($len > 0);
        $y++;
    }
}


sub _headings {
    my $headings = {
        title         => { width => 30, pos =>  5, },
        author        => { width => 30, pos => 40, },
        'call number' => { width => 20, pos => 75, }, 
    };
    return $headings;
}

sub _three_titles {
    my $data = {
        1 => {
            nfc           => 'The ',
            title         => 'moon is a harsh mistress',
            author        => 'Heinlein, Robert A.',
            'call number' => '813.54',
        },
        2 => {
            title         => '2001, A space odyssey',
            author        => 'Clarke, Arthur C.',
            'call number' => '823',
        },
        3 => {
            title         => 'Imaginary numbers',
            author        => 'McGuire, Seanan',
            'call number' => '813.6',
        },
    };
    return $data;
}

sub _fifty_titles {
    my $data = {
        1 => {
           title => 'Ishmael',
           author => 'Quinn, Daniel.',
           'call number' => 'FIC 813.54 Quinn',
        },
        2 => {
           title => 'Mapping time : the calendar and its history',
           author => 'Richards, E. G. (Edward Graham)',
           'call number' => '529.3 RICHA',
        },
        3 => {
           title => 'Build your own Ajax web applications',
           author => 'Eernisse, Matthew.',
           'call number' => '005.434 EERNI',
        },
        4 => {
           title => 'Effects of enrichment problems on attitude, problem solving ability and pattern recognition ability of prospective elementary school teachers',
           author => 'Ouellette, Hugh Francis.',
           'call number' => '372 Ouellette',
        },
        5 => {
            nfc => 'A ',
           title => 'Name to Conjure With',
           author => 'Aamodt, Donald',
           'call number' => 'FANTASY 813.54 Aamodt',
        },
        6 => {
           title => 'Farmer in the sky',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-',
           'call number' => 'SF HEI',
        },
        7 => {
            nfc => 'The ',
           title => 'Door into Summer',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-',
           'call number' => 'SF 813.54 HEINL',
        },
        8 => {
            nfc => 'The ',
           title => 'Door into Summer',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-',
           'call number' => 'SF 813.54 HEINL',
        },
        9 => {
           title => 'Citizen of the galaxy',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-',
           'call number' => 'SF 813.54 HEINL',
        },
        10 => {
           title => 'Owls in the family.',
           author => 'Mowat, Farley.',
           'call number' => 'FIC Mowat',
        },
        11 => {
           title => 'Alone Against Tomorrow',
           author => 'Ellison, Harlan',
           'call number' => 'SF 813.54 ELLIS',
        },
        12 => {
           title => '3-D Starter Kit for Macintosh',
           author => 'Wagstaff, Sean',
           'call number' => '006.6 WAGST',
        },
        13 => {
           title => 'Emergence',
           author => 'Palmer, David R. 1941-',
           'call number' => 'SF Palmer',
        },
        14 => {
            nfc => 'A ',
           title => 'trace of memory',
           author => 'Laumer, Keith, 1925-',
           'call number' => 'SF 813.54 Laumer',
        },
        15 => {
           title => 'Up the line.',
           author => 'Silverberg, Robert.',
           'call number' => 'SF 813.54 SILVE',
        },
        16 => {
           title => 'Old Turtle',
           author => 'Wood, Douglas, 1951-',
           'call number' => 'E 813.54 WOOD',
        },
        17 => {
           title => 'Jeb Stuart, the last cavalier.',
           author => 'Davis, Burke, 1913-',
           'call number' => '973.73 BURKE',
        },
        18 => {
           title => 'Managing the software process / by Watts S. Humphrey',
           author => 'Humphrey, Watts S., 1927-',
           'call number' => '005.1 HUMPH',
        },
        19 => {
           title => 'Calculus :one and several variables, with analytic geometry',
           author => 'Salas, Saturnino L.',
           'call number' => '515 SALAS',
        },
        20 => {
           title => 'Bid time return',
           author => 'Matheson, Richard, 1926-2013.',
           'call number' => 'FIC 813.54 Matheson',
        },
        21 => {
            nfc => 'The ',
           title => "whole Internet user's guide & catalog",
           author => 'Krol, Ed.',
           'call number' => '384.3 KROL',
        },
        22 => {
           title => 'Probability and statistical inference',
           author => 'Hogg, Robert V.',
           'call number' => '519.2 HOGG',
        },
        23 => {
           title => 'Threshold',
           author => 'Palmer, David R.',
           'call number' => 'SF 813.54 Palmer',
        },
        24 => {
           title => 'My name is legion',
           author => 'Zelazny, Roger.',
           'call number' => 'SF 813.54 Zelazny',
        },
        25 => {
           title => 'Voyagers in time; twelve stories of science fiction.',
           author => 'Silverberg, Robert.',
           'call number' => 'SC 813.54 Silverberg',
        },
        26 => {
            nfc => 'The ',
           title => 'Pritcher Mass,',
           author => 'Dickson, Gordon R.',
           'call number' => 'SF 813.54 Dickson',
        },
        27 => {
           title => "Lord Foul's bane",
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        28 => {
            nfc => 'The ',
           title => 'illearth war',
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        29 => {
            nfc => 'The ',
           title => 'power that preserves',
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        30 => {
            nfc => 'The ',
           title => 'power that preserves',
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        31 => {
            nfc => 'The ',
           title => 'wounded land',
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        32 => {
            nfc => 'The ',
           title => 'wounded land',
           author => 'Donaldson, Stephen R.',
           'call number' => 'FANTASY 813.54 DONAL',
        },
        33 => {
           title => 'Spellsinger : novel',
           author => 'Foster, Alan Dean, 1946-',
           'call number' => 'FANTASY 813.54 FOSTE',
        },
        34 => {
           title => 'Double star',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-',
           'call number' => 'SF 813.54 HEINL',
        },
        35 => {
           title => "Hellstrom's hive",
           author => 'Herbert, Frank.',
           'call number' => 'FIC 813.54 Herbert',
        },
        36 => {
            nfc => 'The ',
           title => 'defiant agents,',
           author => 'Norton, Andre.',
           'call number' => 'SF 813.54 Norton',
        },
        37 => {
           title => 'Coils',
           author => 'Zelazny, Roger.',
           'call number' => 'SF 813.54 ZELAZ',
        },
        38 => {
           title => 'Stranger in a strange land.',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-1988.',
           'call number' => 'SF 813.54 HEINL',
        },
        39 => {
           title => "Analog's Children of the future",
           author => 'edited by Stanley Schmidt.',
           'call number' => 'SC 813.54 Schmidt',
        },
        40 => {
           title => 'Cryptanalysis for microcomputers',
           author => 'Foster, Caxton C., 1929-',
           'call number' => '652.8 FOSTE',
        },
        41 => {
           title => 'Father, Son & Co. : my life at IBM and beyond',
           author => 'Watson, Thomas J., 1914-1993',
           'call number' => '338.7 WATSO',
        },
        42 => {
           title => 'Odyssey : Pepsi to Apple--a journey of adventure, ideas, and the future',
           author => 'Sculley, John.',
           'call number' => '331.7 SCULL',
        },
        43 => {
           title => 'Handbook of mathematical tables and formulas.',
           author => 'Burington, Richard Stevens, 1901-',
           'call number' => 'REF 510.212 BURIN',
        },
        44 => {
           title => 'Virus! : the secret world of computer invaders that breed and destroy',
           author => 'Lundell, Allan.',
           'call number' => '005.8 LUNDE',
        },
        45 => {
            nfc => 'The ',
           title => 'time traders',
           author => 'Norton, Andre.',
           'call number' => 'SF 813.54 Norton',
        },
        46 => {
           title => 'Between planets;',
           author => 'Heinlein, Robert A. (Robert Anson), 1907-1988.',
           'call number' => 'SF 813.54 Heinlein',
        },
        47 => {
           title => 'Microbe hunters',
           author => 'De Kruif, Paul, 1890-1971.',
           'call number' => '589.900 DE KRU',
        },
        48 => {
           title => 'Lost continents; the Atlantis theme',
           author => 'De Camp, L. Sprague (Lyon Sprague), 1907-',
           'call number' => '398.23 DeCAMP',
        },
        49 => {
            nfc => 'The ',
           title => 'ship that sailed the time stream.',
           author => 'Edmondson, G. C.',
           'call number' => 'SF 813.54 Edmondson',
        },
        50 => {
           title => 'UNIX in a Nutshell : system V edition :',
           author => 'Gilly, Daniel',
           'call number' => '005.432 GILLY',
        },
        51 => {
           title => '6502 software design',
           author => 'Scanlon, Leo J., 1941-',
           'call number' => '005.265 6502',
        },
        52 => {
            nfc => 'The ',
           title => 'Universe between.',
           author => 'Nourse, Alan E. (Alan Edward)',
           'call number' => 'SF 813.52 Nourse',
        },
        53 => {
           title => 'Illusions : the adventures of a reluctant messiah',
           author => 'Bach, Richard.',
           'call number' => 'FIC 813.54 Bach',
        },
        54 => {
           title => 'Steve Jobs : the journey is the reward',
           author => 'Young, Jeffrey S., 1952-',
           'call number' => '338.7 YOUNG',
        },
        55 => {
           title => 'Something of value',
           author => 'Ruark, Robert Chester, 1915-1965.',
           'call number' => 'FIC 813.54 Ruark',
        },
        56 => {
            title => 'Juggling for the complete klutz',
            author => 'Cassidy, John',
            'call number' => '793.87 Cassidy',
        },
    };
    return $data;
}


