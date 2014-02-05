use warnings;
use strict;

package Net::OpenStack::Networking::Test;

use base 'Test::Class';
use Test::Most tests => 46;
use Test::MockModule;
use Test::MockObject;
use Test::MockObject::Extends;

# TODO: Check queries sent to the server

sub setup_agent : Test(startup => 3) {
    my ($self) = @_;

    $self->{response} =new Test::MockObject();
    $self->{response}->set_true('is_success');
    $self->{response}->set_always('content', '{}');

    $self->{agent} = new Test::MockObject();
    $self->{agent}->set_true('agent', 'ssl_opts', 'proxy');
    $self->{agent}->mock('request' => sub {return $self->{response};});
    $self->{agent}->mock('get' => sub {return $self->{response};});
    $self->{agent}->mock('post' => sub {return $self->{response};});
    $self->{agent}->mock('put' => sub {return $self->{response};});
    $self->{agent}->mock('default_header' => sub {});

    $self->{agent_class} = new Test::MockModule('LWP::UserAgent');
    $self->{agent_class}->mock('new' => $self->{agent});

    use_ok('Net::OpenStack::Networking') or die;

    $self->{networking} = Net::OpenStack::Networking->new(
        auth_url => 'http://dummy.lan/v2.0',
        user     => 'foo',
        password => 'bar'
    );
    $self->{networking} = Test::MockObject::Extends->new($self->{networking});
    $self->{networking}->mock('get_auth_info' => sub {return { base_url => 'http://foo.com/', token => 'TOKEN' };});
    isa_ok($self->{networking}, 'Net::OpenStack::Networking');
}

sub test_instance : Test(1) {
    throws_ok(
        sub { Net::OpenStack::Networking->new },
        qr(Attribute \S+ is required),
        'instantiation with no argument throws an exception'
    );
}

sub test_get_networks : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"networks" : [ {"name": "foo"}, {"name": "bar"}]}');
    my $expected = [{'name' => 'foo'}, {'name' => 'bar'}];

    ok(my $ret = $self->{networking}->get_networks());
    is_deeply( $ret, $expected );
}

sub test_create_network : Test(4) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"network" : {"foo": "bar"}}');
    my $expected = {'foo' => 'bar'};

    throws_ok(
        sub {
            $self->{networking}->create_network(
                name => 'n1');
        },
        qr/invalid data/,
        'create_network() dies with "invalid data" if argument is not a hashref'
    );

    throws_ok(
        sub {
            $self->{networking}->create_network(
                { foo => 'n1' });
        },
        qr/name is required/,
        'create_network() dies if no name provided',
    );

    ok(my $ret = $self->{networking}->create_network({ name => 'n1' }));
    is_deeply( $ret, $expected );
};

sub test_get_network : Test(3) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"network" : {"name": "foo"}}');
    my $expected = {'name' => 'foo'};

    throws_ok(
        sub {
            $self->{networking}->get_network();
        },
        qr/The network id is needed/,
        'get_network() dies with "The network id is needed" if network id is not provided'
    );

    ok(my $ret = $self->{networking}->get_network('1'));
    is_deeply( $ret, $expected );
}

sub test_delete_network : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '');

    throws_ok(
        sub {
            $self->{networking}->delete_network();
        },
        qr/The network id is needed/,
        'delete_network() dies with "The network id is needed" if network id is not provided'
    );

    ok($self->{networking}->delete_network('1'));
}

sub test_get_subnets : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"subnets" : [ {"name": "foo"}, {"name": "bar"}]}');
    my $expected = [{'name' => 'foo'}, {'name' => 'bar'}];

    ok(my $ret = $self->{networking}->get_subnets());
    is_deeply( $ret, $expected );
}

sub test_create_subnet : Test(6) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"subnet" : {"name": "foo"}}');
    my $expected = {'name' => 'foo'};

    throws_ok(
        sub {
            $self->{networking}->create_subnet(
                network_id => 'id1',
                cidr => '192.168.10.0/24',
                ip_version => 4
            );
        },
        qr/invalid data/,
        'create_subnet() dies with "invalid data" if argument is not a hashref'
    );

    throws_ok(
        sub {
            $self->{networking}->create_subnet(
                { cidr => '192.168.10.0/24', ip_version => 4 });
        },
        qr/network_id is required/,
        'create_subnet() dies if no network_id provided',
    );

    throws_ok(
        sub {
            $self->{networking}->create_subnet(
                { network_id => 'id1', ip_version => 4 });
        },
        qr/cidr is required/,
        'create_subnet() dies if no cidr provided',
    );

    throws_ok(
        sub {
            $self->{networking}->create_subnet(
                { network_id => 'id1', cidr => '192.168.10.0/24' });
        },
        qr/ip_version is required/,
        'create_subnet() dies if no ip_version provided',
    );

    ok(my $ret = $self->{networking}->create_subnet({ network_id => 'id1', cidr => '192.168.10.0/24', ip_version => 4 }));
    is_deeply( $ret, $expected );
};

sub test_get_subnet : Test(3) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"subnet" : {"name": "foo"}}');
    my $expected = {'name' => 'foo'};

    throws_ok(
        sub {
            $self->{networking}->get_subnet();
        },
        qr/The subnet id is needed/,
        'get_subnet() dies with "The subnet id is needed" if subnet id is not provided'
    );

    ok(my $ret = $self->{networking}->get_subnet('1'));
    is_deeply( $ret, $expected );
}

sub test_delete_subnet : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '');

    throws_ok(
        sub {
            $self->{networking}->delete_subnet();
        },
        qr/The subnet id is needed/,
        'delete_subnet() dies with "The subnet id is needed" if subnet id is not provided'
    );

    ok($self->{networking}->delete_subnet('1'));
}


sub test_get_routers : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"routers" : [ {"name": "foo"}, {"name": "bar"}]}');
    my $expected = [{'name' => 'foo'}, {'name' => 'bar'}];

    ok(my $ret = $self->{networking}->get_routers());
    is_deeply( $ret, $expected );
}

sub test_create_router : Test(4) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"router" : {"name": "router1"}}');
    my $expected = {'name' => 'router1'};

    throws_ok(
        sub {
            $self->{networking}->create_router(
                name => 'router1',
                network_id => '1',
            );
        },
        qr/invalid data/,
        'create_router() dies with "invalid data" if argument is not a hashref'
    );

    throws_ok(
        sub {
            $self->{networking}->create_router({});
        },
        qr/name is required/,
        'create_router() dies if no name provided',
    );

    ok(my $ret = $self->{networking}->create_router({ name => 'router1'}));
    is_deeply( $ret, $expected );
};

sub test_get_router : Test(3) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"router" : {"name": "foo"}}');
    my $expected = {'name' => 'foo'};

    throws_ok(
        sub {
            $self->{networking}->get_router();
        },
        qr/The router id is needed/,
        'get_router() dies with "The router id is needed" if router id is not provided'
    );

    ok(my $ret = $self->{networking}->get_router('1'));
    is_deeply( $ret, $expected );
}

sub test_delete_router : Test(2) {
    my ($self) = @_;

    $self->{response}->set_always('content', '');

    throws_ok(
        sub {
            $self->{networking}->delete_router();
        },
        qr/The router id is needed/,
        'delete_router() dies with "The router id is needed" if router id is not provided'
    );

    ok($self->{networking}->delete_router('1'));
}

sub test_add_router_interface : Test(4) {
    my ($self) = @_;

    $self->{response}->set_always('content', '{"port_id" : "1"}');
    my $expected = '1';

    throws_ok(
        sub {
            $self->{networking}->add_router_interface();
        },
        qr/The router id is needed/,
        'add_router_interface() dies with "The router id is needed" if router id is not provided'
    );

    throws_ok(
        sub {
            $self->{networking}->add_router_interface('1');
        },
        qr/subnet id is required/,
        'add_router_interface() dies with "subnet id is required" if subnet id is not provided'
    );

    ok(my $ret = $self->{networking}->add_router_interface('1', '1'));
    is_deeply( $ret, $expected );
}

sub test_remove_router_interface : Test(3) {
    my ($self) = @_;

    $self->{response}->set_always('content', '');

    throws_ok(
        sub {
            $self->{networking}->remove_router_interface();
        },
        qr/The router id is needed/,
        'remove_router_interface() dies with "The router id is needed" if router id is not provided'
    );

    throws_ok(
        sub {
            $self->{networking}->remove_router_interface('1');
        },
        qr/port id is required/,
        'remove_router_interface() dies with "port id is required" if subnet id is not provided'
    );

    ok(my $ret = $self->{networking}->remove_router_interface('1', '1'));
}

1;

END {
    Net::OpenStack::Networking::Test->runtests();
}
