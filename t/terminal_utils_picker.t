#!/usr/local/ActivePerl-5.24/bin/perl
use strict;
use utf8;
use Devel::Symdump;
use Test::More tests => 2;
use Test::MockModule;
use Test::Deep;
use Carp::Assert;
use Carp::Assert::More;

my $module = 'Carpecrustum::TerminalUtils';
use_ok ($module);

package Carpecrustum::TerminalUtilsTest;
use parent 'Carpecrustum::TerminalUtils';



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


sub test_picker {
    return subtest picker => sub {
        plan tests => 6;

        my $term = Carpecrustum::TerminalUtilsTest->new();
       
        my $headings = {
            title         => { width => 30, pos =>  5, },
            author        => { width => 30, pos => 40, },
            'call number' => { width => 20, pos => 75, }, 
        };

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


sub _blank_screen {
    my $row = ' ' x 100;
    my @screen;
    foreach my $i ( 1 .. 48 ) {
        push @screen, $row;
    }
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



