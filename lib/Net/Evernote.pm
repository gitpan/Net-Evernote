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

our $VERSION = '0.06';

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

sub writeNote {
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

sub delNote {
    my $self = shift;
    my $guid = shift;
    my $dataUrl = shift || "https://sandbox.evernote.com/edam/note";

    my $authToken = $self->{authToken};
    my $shardId = $self->{shardId};

    $dataUrl .= "/" . $shardId;

    my $transport = Thrift::HttpClient->new($dataUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMNoteStore::NoteStoreClient->new($protocol);

    $transport->open;

    $client->deleteNote($authToken,$guid);
}

sub getNote {
    my $self = shift;
    my $guid = shift;
    my $dataUrl = shift || "https://sandbox.evernote.com/edam/note";

    my $authToken = $self->{authToken};
    my $shardId = $self->{shardId};

    $dataUrl .= "/" . $shardId;

    my $transport = Thrift::HttpClient->new($dataUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMNoteStore::NoteStoreClient->new($protocol);

    $transport->open;

    $client->getNote($authToken,$guid,1);
}

sub findNotes {
    my $self = shift;
    my $string = shift;
    my $offset = shift || 0;
    my $maxNotes = shift || 1;
    my $dataUrl = shift || "https://sandbox.evernote.com/edam/note";

    my $authToken = $self->{authToken};
    my $shardId = $self->{shardId};

    $dataUrl .= "/" . $shardId;
    my $stru = EDAMNoteStore::NoteFilter->new({ words => $string });

    my $transport = Thrift::HttpClient->new($dataUrl);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = EDAMNoteStore::NoteStoreClient->new($protocol);

    $transport->open;

    $client->findNotes($authToken,$stru,$offset,$maxNotes);
}


1;

=head1 NAME

Net::Evernote - Perl client accessing to Evernote


=head1 VERSION

Version 0.06


=head1 SYNOPSIS

    use Net::Evernote;
    my $note = Net::Evernote->new($username, $password, $consumerKey, $consumerSecret);

    # write a note
    my $res = $note->writeNote($title, $content);
    my $guid = $res->guid;

    # get the note
    my $thisNote = $note->getNote($guid);
    print $thisNote->title,"\n";
    print $thisNote->content,"\n";

    # delete the note
    $note->delNote($guid);

    # find notes
    my $search = $note->findNotes("some words",0,5);
    for my $thisNote ( @{$search->notes} ) {
        print $thisNote->guid,"\n";
        print $thisNote->title,"\n";
    }

=head1 METHODS

=head2 new(username, password, consumerKey, consumerSecret, [userStoreUrl])

Initialize the object.

    my $note = Net::Evernote->new("fooUser", "fooPasswd", "fooKey", "fooSecret");

username and password are what you use for login into Evernote.

consumerKey and consumerSecret are got from the email when you signed up to Evernote's API development.

userStoreUrl is the url for user authentication, the default one is https://sandbox.evernote.com/edam/user

If you are in the production development, userStoreUrl should be https://www.evernote.com/edam/user


=head2 writeNote(title, content, [dataStoreUrl])

Write a note to Evernote's server.

    use Data::Dumper;

    my $title = "my Perl poem";
    my $content =<<EOF;
I wrote some Perl to say hello,
To a world I did not know.
Prepended line numbers there in tow,
I basically told it where to go.
EOF

    my ($res,$guid);

    eval {
        $res = $note->writeNote($title, $content);
    };

    if ($@) {
        print Dumper $@;

    } else {
        $guid = $res->guid;
        print "GUID I got for this note is $guid\n";
    }

Both the title and content are strings.

dataStoreUrl is the url for handling note, the default one is https://sandbox.evernote.com/edam/note

If you are in the production development, dataStoreUrl should be https://www.evernote.com/edam/note

About GUID: Most data elements within a user's account (e.g. notebooks, notes, tags, resources, etc.) 
are internally referred to using a globally unique identifier that is written in 
a standard string format, for example, "8743428c-ef91-4d05-9e7c-4a2e856e813a".


=head2 getNote(guid, [dataStoreUrl])

Get the note from the server.

    use Data::Dumper;
    my $thisNote;

    eval {
        $thisNote = $note->getNote($guid);
    };

    if ($@) {
        print Dumper $@;

    } else {
        print $thisNote->title,"\n";
        print $thisNote->content,"\n";
    }

guid is the globally unique identifier for the note.

For the content returned, you must know that they are ENML compatible.
More stuff about ENML please see:

http://www.evernote.com/about/developer/api/evernote-api.htm#_Toc297053072


=head2 delNote(guid, [dataStoreUrl])

Delete the note from Evernote's server.

    use Data::Dumper;

    eval {
        $note->delNote($guid);
    };

    if ($@) {
        print Dumper $@;

    } else {
        print "note with GUID $guid deleted\n";
    }
    
guid is the globally unique identifier for the note.


=head2 findNotes(keywords, offset, maxNotes, [dataStoreUrl])

Find the notes which contain the given keywords.

    use Data::Dumper;
    my $search;

    eval {
        $search = $note->findNotes("some words",0,5);
    };

    if ($@) {
        print Dumper $@;

    } else {
        for my $thisNote ( @{$search->notes} ) {
            print $thisNote->guid,"\n";
            print $thisNote->title,"\n";
        }
    }

offset - The numeric index of the first note to show within the sorted results, default 0

maxNotes - The most notes to return in this query, default 1


=head1 SEE ALSO

http://www.evernote.com/about/developer/api/


=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>

I wish any people who has the interest in this module to work together with it.


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
