package Net::Evernote;

BEGIN {
    my $module_dir = $INC{'Net/Evernote.pm'};
    $module_dir =~ s/Evernote\.pm$//;
    unshift @INC,$module_dir;
}

use 5.006;
use warnings;
use strict;
use Thrift;
use Thrift::HttpClient;
use Thrift::XS::BinaryProtocol;

use EDAMUserStore::UserStore;
use EDAMUserStore::Types;
use EDAMNoteStore::NoteStore;
use EDAMNoteStore::Types;
use EDAMErrors::Types;
use EDAMLimits::Types;  
use EDAMTypes::Types;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $username = shift;
    my $password = shift;
    my $consumerKey = shift;
    my $consumerSecret = shift;
    my $authUrl = shift || "https://sandbox.evernote.com/edam/user";

    my $transport = Thrift::HttpClient->new($authUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMUserStore::UserStoreClient->new($protocol);

    $transport->open;

    my $re = $client->authenticate($username,$password,$consumerKey,$consumerSecret);

    bless { 
            authToken => $re->authenticationToken,
            shardId   => $re->user->shardId,
          }, $class;
}

sub postNote {
    my $self = shift;
    my $title = shift;
    my $content = shift;
    my $dataUrl = shift || "https://sandbox.evernote.com/edam/note";

    $content =~ s/\n/<br\/>/g;
    my $cont_encoded =<<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
    $content
</en-note>
EOF

    my $authToken = $self->{authToken};
    my $shardId = $self->{shardId};

    $dataUrl .= "/" . $shardId;

    my $transport = Thrift::HttpClient->new($dataUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMNoteStore::NoteStoreClient->new($protocol);

    $transport->open;

    my $note = EDAMTypes::Note->new({ title => $title, 
                                      content => $cont_encoded,
                                    });

    $client->createNote($authToken,$note);
}


1;


=head1 NAME

Net::Evernote - Perl client accessing to Evernote


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Net::Evernote;
    my $note = Net::Evernote->new($username, $password, $consumerKey, $consumerSecret);
    $note->postNote($title, $content);


=head1 METHODS

=head2 new(username, password, consumerKey, consumerSecret, [userStoreUrl])

Initialize the object.

    my $note = Net::Evernote->new("fooUser", "fooPasswd", "fooKey", "fooSecret");

username and password are what you use for login into Evernote.

consumerKey and consumerSecret are got from the email when you signed up to Evernote's API development.

userStoreUrl is the url for user authentication, the default one is https://sandbox.evernote.com/edam/user

If you are in the production development, userStoreUrl should be https://www.evernote.com/edam/user


=head2 postNote(title, content, [dataStoreUrl])

    use Data::Dumper;

    my $title = "my Perl poem";
    my $content =<<EOF;
I wrote some Perl to say hello,
To a world I did not know.
Prepended line numbers there in tow,
I basically told it where to go.
EOF

    eval {
        $note->postNote($title, $content);
    };

    if ($@) {
        print Dumper $@;
    }

Both the title and content are strings.

dataStoreUrl is the url for posting note, the default one is https://sandbox.evernote.com/edam/note

If you are in the production development, dataStoreUrl should be https://www.evernote.com/edam/note


=head1 SEE ALSO

    http://www.evernote.com/about/developer/api/


=head1 AUTHOR

Ken Peng <shorttag@gmail.com>

I wish any people who has the interest in this module to work together with it.


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <shorttag@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
