#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Evernote' ) || print "Bail out!\n";
}

diag( "Testing Net::Evernote $Net::Evernote::VERSION, Perl $], $^X" );
