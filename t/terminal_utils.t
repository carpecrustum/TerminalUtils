#!/usr/local/ActivePerl-5.24/bin/perl
use strict;
use utf8;
use Devel::Symdump;
use Test::More;
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
    my $term = Carpecrustum::TerminalUtilsTest->new();
    if (($term->width() == 100) && ($term->height() == 48)) {
        plan tests => 8;

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
    }
    else {
        plan skip_all => 'These tests must run in a 100x48 terminal window.';
    };
    done_testing();
}


sub test_dimensions {
    my $term = Carpecrustum::TerminalUtilsTest->new();
    return subtest dimensions => sub {
        plan tests => 2;
        is ($term->width(), 100, "Width is correct");
        is ($term->height(), 48, "Height is correct");
    };
}

sub test_get_screen {
    my $term = Carpecrustum::TerminalUtilsTest->new();
    my @screen_lines = $term->get_screen();
    my $expected_lines = 48;
    my $actual_lines = scalar @screen_lines;
    is ($actual_lines, $expected_lines, "screen height is correct");
}


sub test_reset_screen {
    return subtest reset_screen => sub {
        plan tests => 48;
        my $term = Carpecrustum::TerminalUtilsTest->new();
        $term->reset_screen();
        my @screen_lines = $term->get_screen();
        foreach my $line (1 .. $#screen_lines + 1) {
            is ($screen_lines[$line - 1], ' ' x 100, "line $line is correct");
        }
    };
}

sub test_blank_screen {
    return subtest blank_screen => sub {
        plan tests => 48;
        my @screen_lines = _blank_screen();
        foreach my $line (1 .. $#screen_lines + 1) {
            is ($screen_lines[$line - 1], ' ' x 100, "line $line is correct");
        }
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

sub test_menu {
    return subtest menu => sub {
        plan tests => 2;
        my $term = Carpecrustum::TerminalUtilsTest->new();
        my $x = 38;
        my $y = 3;
        my $len = 24;
        my @expected = _blank_screen();
        my $image = <<IMAGE;
┌──────────────────────┐
│      Main Menu       │
├──────────────────────┤
│                      │
│  1. one              │
│  2. two              │
│  3. three            │
│  Quit                │
│                      │
└──────────────────────┘
IMAGE

        add_to_screen($x, $y, \@expected, $image);
        $term->reset_screen();
        my $options = {
            title => 'Main Menu',
            choices => [
                "1. one", 
                "2. two", 
                "3. three",
            ], 
            exit => 'Quit',
        };
        $term->menu($options);

        my @actual = $term->get_screen();
        margin_is(\@actual, \@expected, "left margin is correct");

        my @expected_menu = strip_margins(\@expected);
        my @actual_menu = strip_margins(\@actual);
        array_is(\@actual_menu, \@expected_menu, "menu was drawn correctly");
    }
}


sub test_title_box {
    return subtest title_box => sub {
        plan tests => 1;
        my $term = Carpecrustum::TerminalUtilsTest->new();
        
        my @expected = _blank_screen();
        my $base_x = 5;
        my $base_y = 10;
        my $image = <<IMAGE;
┌──────────────────────┐
│                      │
├──────────────────────┤
│                      │
│                      │
│                      │
│                      │
└──────────────────────┘
IMAGE

        add_to_screen( $base_x, $base_y, \@expected, $image );

#                                                          123456789012345678901234
        $term->reset_screen();
        $term->title_box($base_x, $base_y, 24, 8);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "box was drawn correctly");
    };
}


sub test_draw_box {
    return subtest draw_box => sub {
        plan tests => 8;
        my $term = Carpecrustum::TerminalUtilsTest->new();
    
        # test normal box
        my $x = 6;
        my $y = 2;
        my @expected = _blank_screen();
        my $image = <<IMAGE;
┌──────────────────────┐
│                      │
│                      │
│                      │
│                      │
│                      │
│                      │
└──────────────────────┘
IMAGE
        add_to_screen( $x, $y, \@expected, $image );
        $term->reset_screen();
        $term->box($x, $y, 24, 8);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "box was drawn correctly");

        # test minimal box
        $y = 2;
        $x = 6;
        @expected = _blank_screen();
        $image = <<IMAGE;
┌┐
└┘
IMAGE
        add_to_screen( $x, $y, \@expected, $image );
        $term->reset_screen();
        $term->box($x, $y, 2, 2);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "minimal box was drawn correctly");


        # test width < 2 box
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(5, 1, 1, 2);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "width is too small box was drawn correctly");

        # test height < 2 box
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(5, 1, 2, 1);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "height is too small box was drawn correctly");

        # test box crosses top
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(-5, 1, 5, 5);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "no box drawn - top is out of bounds");

        # test box crosses bottom
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(5, 44, 5, 5);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "no box drawn - bottom is out of bounds");

        # test box crosses left
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(5, -1, 5, 5);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "no box drawn - left is out of bounds");

        # test box crosses right
        @expected = _blank_screen();
        $term->reset_screen();
        $term->box(100, 5, 5, 5);
        my @actual = $term->get_screen();
        array_is(\@actual, \@expected, "no box drawn - right is out of bounds");
    };
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

    my @seg = split( /[\n\r]+/, $image );
    
    # convert from 1-based to 0-based
    $x = $x - 1;
    $y = $y - 1;

    foreach my $seg (@seg) {
        my $len = length($seg);
        substr($$screen_ref[$y++], $x, $len) = $seg;
    }
}


