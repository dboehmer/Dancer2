package Dancer2::Core::Error2;
# ABSTRACT: Error objects for Dancer2

use Moo;
use MooX::Types::MooseLike::Base qw<Str>;
use Dancer2::Core::HTTP;
use Devel::StackTrace::AsHTML;
extends 'Throwable::Error';

has status => (
    is      => 'ro',
    isa     => sub {
        $_[0] && $_[0] =~ /^[0-9]{3}$/
            or die 'status must be a three digit number';
    },
    default => sub {500},
);

has title => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self   = shift;
        my $status = $self->status;
        return sprintf "$status " .
            Dancer2::Core::HTTP->status_message($status);
    },
);

1;

