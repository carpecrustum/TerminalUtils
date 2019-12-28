package Carpecrustum::TerminalUtils;

use 5.010;
use strict;
use warnings;

use utf8;
use Term::Cap;
use Term::ANSIColor;
use Term::ReadKey;
use Term::RawInput;
use Time::HiRes;
use Carp::Assert;

=head1 NAME

Utilities for terminal applications

A wrapper around screen positioning tools. It contains methods 
for drawing boxes and menus.
Origin (1, 1) is top left.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Carpecrustum::TerminalUtils;

    my $foo = Carpecrustum::TerminalUtils->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new( $debug )

Create a C<Terminal_Utils> object.

If called from a test (.t) file, then $self->{testing}
is set to true, and all of the output will be written
into an array of strings rather than going to the screen
and $self->get_screen() will return the array for testing.

Parameters:
   $debug - 

=cut

sub new {
    my $class = shift;
    my $debug = shift // 0;
    my ($package, $filename, $line) = caller;
    
    my $self  = bless {}, $class;
    $self->{terminal} = undef;
    $self->_initialize_terminal();

    $self->{rows} = 48;
    $self->{columns} = 100;
    $self->reset_screen();
    $self->{debug} = $debug;
    $self->{testing} = $filename =~ /\.t$/;
    return $self;
}


=head2 $self->is_test()

Returns true if this is for a test.

=cut

sub is_test {
    my $self = shift;
    return $self->{testing};
}


=head2 $self->reset_screen()

TODO

=cut

sub reset_screen {
    my $self = shift;
    my $row = ' ' x $self->{columns};
    $self->{screen} = [];
    foreach my $i ( 1 .. $self->{rows} ) {
        push @{$self->{screen}}, $row;
    }
    return;
}


=head2 $self->get_screen()

Returns the screen image array if this is a test, otherwise return C<undef>.

=cut

# TODO - handle C<undef> 
sub get_screen {
    my $self = shift;
    return @{$self->{screen}};
}


sub width {
    my $self = shift;
    return $self->{columns};
}


sub height {
    my $self = shift;
    return $self->{rows};
}


sub test_grid {
    my $self = shift;
    my $line = "";
    for my $i ( 1 .. int($self->width() / 10) ) {
        $line .= ' ' x 9;
        $line .= "$i";
    }
    print $self->{terminal}->Tgoto("cm", 3, 0);
    print substr($line, 0, $self->width() - 3);

    $line = '1234567890' x  int($self->width() / 10);
    print $self->{terminal}->Tgoto("cm", 3, 1);
    print substr($line, 0, $self->width() - 3);

    for my $i (1 .. $self->height() - 2) {
        print $self->{terminal}->Tgoto("cm", 0, $i + 1);
        printf "%02d", $i;
    }
}
    


sub home {
    my $self = shift;
    if (!$self->is_test() ) {
        system("clear");
    }
    if ($self->is_debugging()) {
        $self->reset_screen();
        $self->test_grid();
    }
    return;
}


=head2 $self->move( $x, $y)

Position the cursor at x, y. x and y are 1-based.

=cut

sub move {
    my $self = shift;
    my $x = shift // 1;
    my $y = shift // 1;

    if ($self->is_debugging()) {
        $y += 2;
        $x += 3;
    }
    print $self->{terminal}->Tgoto("cm", $x - 1, $y - 1 ); # 0-based
} 


=head2 $self->line( $text, $x, $y )

Draws the text at x,y. x and y are 1-based.

If this is run within a test, then the C<$self->{screen}> array
will be updated instead of drawing the string in the terminal
window and the color codes will not be in the array.

If debugging is turned on, then this will be offset vertically
by two rows so that the scale will be shown.

=cut

sub line {
    my $self = shift;
    my $text = shift;
    my $x = shift // 1;
    my $y = shift // 1;

    if ($self->is_test() ) {
        my $plaintext = Term::ANSIColor::colorstrip($text);
        my $size = length($plaintext);
        substr(${$self->{screen}}[$y - 1], $x - 1, $size) = $plaintext;
    }
    else { 
        if ($self->is_debugging()) {
            $y += 2;
        }
        $self->move( $x, $y );
        print $text;
        $self->move( 1, 1);
    }
}
   

sub is_debugging {
    my $self = shift;
    return $self->{debug};
} 

sub title_box {
    my $self = shift;
    my $x = shift; # coordinate of top left
    my $y = shift;
    my $width = shift;
    my $height = shift;
    if ($height < 5) {
       return;
    }
    $self->box($x, $y, $width, $height);

    my $horiz     = "\N{BOX DRAWINGS LIGHT HORIZONTAL}";
    my $left_mid  = "\N{BOX DRAWINGS LIGHT VERTICAL AND RIGHT}";
    my $right_mid = "\N{BOX DRAWINGS LIGHT VERTICAL AND LEFT}";
    my $mid_line = $left_mid . ($horiz x ($width - 2)) . $right_mid;
    $self->line ($mid_line, $x, $y + 2);
}

    
sub box {
    my $self = shift;
    my $x = shift; # coordinate of top left
    my $y = shift;
    my $width = shift;
    my $height = shift;

    my $vert      = "\N{BOX DRAWINGS LIGHT VERTICAL}";
    my $horiz     = "\N{BOX DRAWINGS LIGHT HORIZONTAL}";
    my $corner_1  = "\N{BOX DRAWINGS LIGHT DOWN AND RIGHT}";
    my $corner_2  = "\N{BOX DRAWINGS LIGHT DOWN AND LEFT}";
    my $corner_3  = "\N{BOX DRAWINGS LIGHT UP AND RIGHT}";
    my $corner_4  = "\N{BOX DRAWINGS LIGHT UP AND LEFT}";
    my $left_mid  = "\N{BOX DRAWINGS LIGHT VERTICAL AND RIGHT}";
    my $right_mid = "\N{BOX DRAWINGS LIGHT VERTICAL AND LEFT}";

    if (($width < 2) || ($height < 2)) {
       return;
    }
    if (($x < 1) || (($x + $width) > $self->width())) {
        return;
    }

    if (($y < 1) || (($y + $height) > $self->height())) {
        return;
    }

    my $side_width = $width - 2;
    my $white_width = $width + 2;

    my $top      = $corner_1 . ($horiz x $side_width) . $corner_2;
    my $mid_gap  = $vert     . (" "    x $side_width) . $vert;
    my $mid_line = $left_mid . ($horiz x $side_width) . $right_mid;
    my $bot      = $corner_3 . ($horiz x $side_width) . $corner_4;
    my $white    = " " x $white_width;

    my $top_white = ($y == 1) ? $y : $y - 1;
    my $bottom_white = (($y + $height) == $self->height()) ? $y + $height : $y + $height + 1;

    for my $y ($top_white .. $bottom_white) {
        $self->line ($white, $x - 1, $y);
    }

    $self->line($top, $x, $y);
    for my $offset (1 .. $height - 2) {
        $self->line($vert, $x, $y + $offset);
        $self->line($vert, $x + $side_width + 1, $y + $offset);
    }

    $self->line($bot, $x, $y + $height - 1);
}


sub _initialize_terminal {
    require POSIX;
    my $self = shift;

    my $termios = POSIX::Termios->new();
    $termios->getattr;
    my $ospeed = $termios->getospeed;
    # Old-style ioctl code to get ospeed:
    #     require 'ioctl.pl';
    #     ioctl(TTY,$TIOCGETP,$sgtty);
    #     ($ispeed,$ospeed) = unpack('cc',$sgtty);
    # allocate and initialize a terminal structure
    #$terminal = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
    # require certain capabilities to be available
    #$terminal->Trequire(qw/ce ku kd/);

    $self->{terminal} = Term::Cap->Tgetent({ TERM => undef, OSPEED => $ospeed });
    $self->{terminal}->Trequire(qw/ce ku kd/);
    if (0) {
        home();
        print $self->{terminal}->Tgoto("cm", 0, 0);
        print join (' ' x 9, (0 .. 7)); # "0         1         2         3         4";
        print $self->{terminal}->Tgoto("cm", 0, 1);
        print "" . ("0123456789" x 7 ) . "0"; #0123456789012345678901234567890";
    }
    return;
}

sub menu {
    my $self = shift;
    my $options = shift;
    my $width = 24;
    my $x1 = int(($self->width() - $width) / 2 + 0.5);
    my $msg = "";
    my $space = $width - 2;
    my $needed = length($options->{title});
    my $left = int(($space - $needed)/2 + 0.5);
    my $y1 = 1; 
    
    my @list;

    my $y2 = 7 + scalar(@{$options->{choices}}); 
    $self->title_box($x1, $y1, $width, $y2);
    $self->line($options->{title}, $x1 + $left, $y1 + 1);
    my $choice_y = $y1 + 4;
    foreach my $line (@{$options->{choices}}) {
        push @list, $line;
        $self->line($line, $x1 + 3, $choice_y++);
    }
    $self->line("$options->{exit}", $x1 + 3, $y2 + $y1 - 3);
    push @list, $options->{exit};

    my $choice = -1;
    if (! $self->{testing} ) {
        my $pos = 0;
        while ($choice < 0) {
            $self->line( colored(['white on_black'], $list[$pos]), $x1 + 3, $y1 + 4 + $pos);
            my $key = $self->get_key();
            $self->line( $list[$pos], $x1 + 3, $y1 + 4 + $pos);
            if ($key eq 'ENTER') {
                $choice = $pos;
            }
            elsif ($key eq "UPARROW" || $key eq "LEFTARROW") {
                $pos = ($pos == 0) ? $#list : $pos - 1;
            }
            elsif ($key eq "DOWNARROW" || $key eq "RIGHTARROW") {
                $pos = ($pos == $#list) ? 0 : $pos + 1;   
            }
        }
        $self->line("User chose: $list[$choice]", 1, 24) if ($self->is_debugging());
    }
    return $list[$choice];
}

sub get_key {
    my $self = shift;
    my ($char, $key) = rawInput("", 1);
    my $ret_char = (length($key) > 0) ? $key : $char;
    return $ret_char;
}




=head1 AUTHOR

Tim Wentz, C<< <carpecrustum at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-carpecrustum-terminalutils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carpecrustum-TerminalUtils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Carpecrustum::TerminalUtils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Carpecrustum-TerminalUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carpecrustum-TerminalUtils>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Carpecrustum-TerminalUtils>

=item * Search CPAN

L<https://metacpan.org/release/Carpecrustum-TerminalUtils>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Tim Wentz.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Carpecrustum::TerminalUtils
