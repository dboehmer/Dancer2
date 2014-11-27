use strict;
use warnings;
use JSON;
use Test::More tests => 4;
use Plack::Test;
use HTTP::Request::Common;

{
    package App;
    use Dancer2;
    set serializer => 'JSON';
    set logger => 'Capture';

    get '/error' => sub {
        send_error 'This is a custom error message';
        return 'send_error returns so this content is not processed';
    };

    get '/error/:foo' => sub {
        my $foo = param('foo');
        send_error "Error 5$foo", "5$foo";
    };
}

{
    package App::Die;
    use Dancer2;
    set logger => 'Capture';
    get '/die' => sub {
        # this will be the message in a serialized output
        die "oh noes\n";
    };
}

{
    package App::Die::Serialized;
    use Dancer2;
    set logger => 'Capture';
    set serializer => 'JSON';
    get '/die' => sub {
        # this will be the message in a serialized output
        die "oh noes\n";
    };
}

subtest 'Route calls send_error' => sub {
    my $test = Plack::Test->create( App->to_app );
    my $res  = $test->request( GET '/error' );

    is( $res->code, 500, 'send_error sets the status to 500' );

    my $struct = decode_json $res->content;
    is_deeply(
        $struct,
        {
            title   => '500 Internal Server Error',
            message => 'This is a custom error message',
            status  => 500,
        },
        'Correct error object returned',
    );

    is(
        $res->content_type,
        'application/json',
        'Response has appropriate content type after serialization',
    );
};

subtest 'Route calls send_error with custom information' => sub {
    my $test = Plack::Test->create( App->to_app );
    my $res  = $test->request( GET '/error/10' );

    is( $res->code, 510, 'send_error sets the status to 510' );

    my $struct = decode_json $res->content;
    is_deeply(
        $struct,
        {
            title   => '510 Not Extended',
            message => 'Error 510',
            status  => 510,
        },
        'Correct error object returned',
    );
};

subtest 'App dies with shitty default' => sub {
    my $test = Plack::Test->create( App::Die->to_app );
    my $res  = $test->request( GET '/die' );

    is( $res->code, 500, '/die returns 500' );
    is( $res->content_type, 'text/html', 'Correct content type' );

    my $error_str =
          "500 Internal Server Error<br><br>oh noes\n";

    is( $res->content, $error_str, 'Error template rendered successfully' );
};

__END__
subtest 'App dies with rendered error page' => sub {
    my $test = Plack::Test->create( App::Die->to_app );
    my $res  = $test->request( GET '/die' );

    is( $res->code, 500, '/die returns 500' );
    is( $res->content_type, 'text/html', 'Correct content type' );

    my $error_str =
          "Title:Error 500 - Internal Server Error,"
        . "Message:oh noes,"
        . "Status:500";

    is( $res->content, $error_str, 'Error template rendered successfully' );
};

__END__
subtest 'App dies with serialized error' => sub {
    my $test = Plack::Test->create( App::Die::Serialized->to_app );
    my $res  = $test->request( GET '/die' );

    is( $res->code, 500, '/die returns 500' );
    is( $res->content_type, 'application/json', 'Correct content type' );

    my $struct = decode_json $res->content;
    is_deeply(
        $struct,
        {
            title   => 'Error 500 - Internal Server Error',
            message => "oh noes\n",
            status  => 500,
        },
        'Correct structure',
    );
};

