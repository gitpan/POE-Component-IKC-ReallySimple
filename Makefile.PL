use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'POE::Component::IKC::ReallySimple',
    VERSION_FROM => 'VERSION', # finds $VERSION
    AUTHOR       => 'Matt Cashner (eek+cpan@eekeek.org)',
    ABSTRACT     => 'Wrapper to make IKC really simple',
    PREREQ_PM    => {
        POE      => 0,
        POE::Component::IKC::Server => 0, #IKC has a cpan bug
        Test::More => 0,
    },
);
