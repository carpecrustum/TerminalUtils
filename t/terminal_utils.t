#!/usr/local/ActivePerl-5.24/bin/perl
use strict;
use utf8;
use Devel::Symdump;
use Test::More tests => 9;
use Test::MockModule;
use Test::Deep;
use Carp::Assert;
use Carp::Assert::More;
use JSON;

my $module = 'Carpecrustum::TerminalUtils';
use_ok ($module);

package Carpecrustum::TerminalUtilsTest;
use parent 'Carpecrustum::TerminalUtils';

sub _show_stack {
     my $self = shift;
    my $frames = scalar(@{$self->{stack}});
    if ($frames == 0) {
        Test::More::diag( "Stack is empty" );
    }
    else {
        Test::More::diag( "Stack has $frames frames." );
        foreach my $f (1 .. $frames) {
            my $sf = JSON::decode_json($self->{stack}->[$f - 1]);
            Test::More::diag( "===================== Stack Frame #$f ==========================" );
            my $last_line = 48;
            foreach my $row (reverse 1 .. 48) {
                if ($sf->[$row -1] !~ /^ +$/) {
                    $last_line = $row;
                    last;
                }
            }
            foreach my $row (1 .. $last_line) {
                Test::More::diag( sprintf( "[%2d] %s\n", $row, $sf->[$row - 1] ));
            }
            if ($last_line != 48) {
                Test::More::diag( "" );
                $last_line++;
                Test::More::diag( "Lines $last_line through 48 are blank" );
                Test::More::diag( "" );
            }
        }
        Test::More::diag( "==============================================================" );
    }
}

sub _sample_text {
    my $self = shift;
    my $x = shift;
    my $y = shift;
    my $paragraph = shift;

    my $text = [
        [
            'Computerwocky (With apologies to Lewis Carroll) ',
            '(by John P. Dominik) ',
        ],
        [
            'Twas digital, and the binary bits',
            '    did gire and gimbole in the core',
            'All mimsy were the registers, ',
            '    and the mainframe outbore. ',
        ],
        [
            'Beware the Computerwock, My son ',
            '    the bugs in bytes, the cards that patch ',
            'Beware the GIGO bird, and shun',
            '    the fumrirous bandersnatch ',
        ],
        [
            'He took his on line Pen in hand! ',
            '    long time the mini-max he sought',
            'So rested he by the logic tree,',
            '    and programmed it in through. ',
        ],
        [
            'And as in uffish thought he stood ',
            '    the computer wock, with console lights, ',
            'Came wiffling through the I/O queue, ',
            '    and burbled bits to bytes! ',
        ],
        [
            'One! Two! and through and through, ',
            '    the input pen went snicker snack',
            'He left it dead, its dump unread, ',
            '    and went galumphing back. ',
        ],
        [
            'And hast thou slain the Computerwock, my son ',
            '    come into my arms, my beamish boy!',
            'Oh fabulous day! I/O! Overlay! ',
            '    he chortled in his joy. ',
        ],
        [
            'Twas digital, and the binary bits',
            '    did gire and gimbole in the core',
            'All mimsy were the registers, ',
            '    and the mainframe outbore. ',
        ],
        [
            '(The light pen is mighter than the Vorpal Sword)',
        ],
    ];
    foreach my $line (@{$text->[$paragraph]}) {
        $self->line($line, $x, $y++);
    }
    return;
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


sub test_push_pop {
    return subtest draw_box => sub {
        plan tests => 4;
        my $term = Carpecrustum::TerminalUtilsTest->new();
       
        $term->_show_stack(); 
        # popping an empty stack returns a blank screen
        $term->_sample_text( 2, 2, 0);
        $term->_sample_text( 2, 5, 1);
        my @actual = $term->get_screen();

my $image = <<TEXT;
Computerwocky (With apologies to Lewis Carroll) 
(by John P. Dominik) 

Twas digital, and the binary bits
    did gire and gimbole in the core
All mimsy were the registers, 
    and the mainframe outbore. 
TEXT

        my @expected = _blank_screen();             # start with blank screen
        add_to_screen( 2, 2, \@expected, $image );  # draw the text block into the expected screen
        my @actual = $term->get_screen();           # retrieve the screend data
        array_is(\@actual, \@expected, "text was drawn correctly");

        $term->pop_screen();
        array_is(\@actual, \@expected, "screen not changed by unpaired pop_screen");

        $term->push_screen();       

        # stash the current screen for the next result
        my @saved_screen = $term->get_screen();
    
        $term->_show_stack(); 

        # add another paragraph 
        my $text = <<TEXT;
Beware the Computerwock, My son 
    the bugs in bytes, the cards that patch 
Beware the GIGO bird, and shun
    the fumrirous bandersnatch 
TEXT
        # draw another box on the screen and add it to
        # the test array
        add_to_screen( 9, 10, \@expected, $text );
        $term->_sample_text(9, 10, 2);
        my @actual = $term->get_screen();

        array_is(\@actual, \@expected, "got both paragraphs");
        $term->push_screen();
        $term->_show_stack(); # check for two stack frames
        $term->pop_screen();  # get rid of frame 2
        $term->pop_screen();  # get rid of frame 1

        @actual = $term->get_screen();
        array_is(\@actual, \@saved_screen, "saved screen was restored correctly");
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


