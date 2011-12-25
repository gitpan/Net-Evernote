use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Evernote',
    AUTHOR              => q{Ken Peng <shorttag@gmail.com>},
    VERSION_FROM        => 'lib/Net/Evernote.pm',
    ABSTRACT_FROM       => 'lib/Net/Evernote.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'Crypt::SSLeay' => 0,
        'Thrift::XS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Evernote-*' },
);
