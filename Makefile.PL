use ExtUtils::MakeMaker;

WriteMakefile(
    NAME    => 'Net::OpenStack::Networking',
    LICENSE => 'GPL2',
    VERSION => '0.1',
    PREREQ_PM => {
        "Moose" => 0,
        "HTTP::Request" => 0,
        "JSON" => 0,
        "LWP" => 0,
        "Test::Class" => 0,
        "Test::Most" => 0,
        "Test::MockModule" => 0,
        "Test::MockObject" => 0,
        "Test::MockObject::Extends" => 0,
    },
    EXE_FILES => [
        "bin/osmnetworking"
    ],
);
