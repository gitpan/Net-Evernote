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

our $VERSION = '0.01';

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

    my $authToken = $self->{authToken};
    my $shardId = $self->{shardId};

    $dataUrl .= "/" . $shardId;

    my $transport = Thrift::HttpClient->new($dataUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMNoteStore::NoteStoreClient->new($protocol);

    $transport->open;

    my $note = EDAMTypes::Note->new({title=>$title, content=>$content});

    $client->createNote($authToken,$note);
}


1;


=head1 NAME

Net::Evernote - Perl client accessing to Evernote


=head1 VERSION

Version 0.01

The very begin version, welcome anyone who has interest to join the development team.


=head1 SYNOPSIS

    use Net::Evernote;
    my $note = Net::Evernote->new($username,$password,$consumerKey,$consumerSecret);
    $note->postNote($title,$content);


=head1 METHODS

=head2 new(username,password,consumerKey,consumerSecret,[userStoreUrl])

Initialize the object.

    my $note = Net::Evernote->new($username,$password,$consumerKey,$consumerSecret);

The consumerKey and consumerSecret are got from the email when you signed up with Evernote's API development.

The userStoreUrl is the url for user authentication, the default one is https://sandbox.evernote.com/edam/user

If you are in the production development, userStoreUrl should be https://www.evernote.com/edam/user

For accessing them, Net::SSLeay and Crypt::SSLeay along with Thrift module are needed.

=head2 postNote(title,content,[dataStoreUrl])

    use Data::Dumper;

    eval {
        $note->postNote($title,$content);
    };

    if ($@) {
        print Dumper $@;
    }

The title is a common string. The content is a XHTML string.

The dataStoreUrl is the url for posting note, the default one is https://sandbox.evernote.com/edam/note

If you are in the production development, dataStoreUrl should be https://www.evernote.com/edam/note

For accessing them, Net::SSLeay and Crypt::SSLeay along with Thrift module are needed.


=head1 SEE ALSO

http://www.evernote.com/about/developer/api/


=head1 AUTHOR

Ken Peng <shorttag@gmail.com>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <shorttag@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
