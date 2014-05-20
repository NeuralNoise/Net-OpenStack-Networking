# Copyright (C) 2014 Zentyal S.L.
# Based on Net::OpenStack::Compute by Naveed Massjouni
# https://github.com/ironcamel/Net-OpenStack-Compute
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;

package Net::OpenStack::Networking;

use Moose;
use HTTP::Request;
use JSON qw(from_json to_json);
use LWP;
use Net::OpenStack::Exception;

has auth_url => (is => 'rw', required => 1);
has user => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has project_id => (is => 'ro', default => 'demo');
has region => (is => 'ro');
has service_name => (is => 'ro', default => 'neutron');
has is_rax_auth => (is => 'ro');
has verify_ssl => (is => 'ro', default => 1);

has base_url => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->_auth_info->{base_url} . '/v2.0/' },
);
has token => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->_auth_info->{token} },
);
has _auth_info => (is => 'ro', lazy => 1, builder => '_build_auth_info');

has _agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new(
            ssl_opts => { verify_hostname => $self->verify_ssl });
        return $agent;
    },
);

with 'Net::OpenStack::AuthRole';

sub BUILD {
    my ($self) = @_;
    # Make sure trailing slashes are removed from auth_url
    my $auth_url = $self->auth_url;
    $auth_url =~ s|/+$||;
    $self->auth_url($auth_url);
}

sub _build_auth_info {
    my ($self) = @_;
    my $auth_info = $self->get_auth_info();
    $self->_agent->default_header(x_auth_token => $auth_info->{token});
    return $auth_info;
}

sub _get_query {
    my %params = @_;
    my $q = $params{query} or return '';
    for ($q) { s/^/?/ unless /^\?/ }
    return $q;
};

sub get_networks {
    my ($self, %params) = @_;
    my $q = _get_query(%params);
    my $res = $self->_get("/networks", $q);
    return from_json($res->content)->{networks};
}

sub create_network {
    my ($self, $data) = @_;
    throw Net::OpenStack::Exception("invalid data") unless $data and 'HASH' eq ref $data;
    throw Net::OpenStack::Exception("name is required") unless defined $data->{name};
    my $res = $self->_post("/networks", { network => $data });
    return from_json($res->content)->{network};
}

sub get_network {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The network id is needed") unless $id;
    my $res = $self->_get("/networks/$id");
    return undef unless $res->is_success;
    return from_json($res->content)->{network};
}

# TODO: Update (put)

sub delete_network {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The network id is needed") unless $id;
    $self->_delete("/networks/$id");
    return 1;
}

sub get_subnets {
    my ($self, %params) = @_;
    my $q = _get_query(%params);
    my $res = $self->_get("/subnets", $q);
    return from_json($res->content)->{subnets};
}

sub create_subnet {
    my ($self, $data) = @_;
    throw Net::OpenStack::Exception("invalid data") unless $data and 'HASH' eq ref $data;
    throw Net::OpenStack::Exception("network_id is required") unless defined $data->{network_id};
    throw Net::OpenStack::Exception("cidr is required") unless defined $data->{cidr};
    throw Net::OpenStack::Exception("ip_version is required") unless defined $data->{ip_version};
    my $res = $self->_post("/subnets", { subnet => $data });
    return from_json($res->content)->{subnet};
}

sub get_subnet {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The subnet id is needed") unless $id;
    my $res = $self->_get("/subnets/$id");
    return undef unless $res->is_success;
    return from_json($res->content)->{subnet};
}

# TODO: Update (put)

sub delete_subnet {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The subnet id is needed") unless $id;
    $self->_delete("/subnets/$id");
    return 1;
}

# l3

sub get_routers {
    my ($self, %params) = @_;
    my $q = _get_query(%params);
    my $res = $self->_get("/routers", $q);
    return from_json($res->content)->{routers};
}

sub create_router {
    my ($self, $data) = @_;
    throw Net::OpenStack::Exception("invalid data") unless $data and 'HASH' eq ref $data;
    throw Net::OpenStack::Exception("name is required") unless defined $data->{name};
    #throw Net::OpenStack::Exception("network_id is required") unless defined $data->{network_id};
    my $res = $self->_post("/routers", { router => $data });
    return from_json($res->content)->{router};
}

sub get_router {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The router id is needed") unless $id;
    my $res = $self->_get("/routers/$id");
    return undef unless $res->is_success;
    return from_json($res->content)->{router};
}

# TODO: Update (put)

sub delete_router {
    my ($self, $id) = @_;
    throw Net::OpenStack::Exception("The router id is needed") unless $id;
    $self->_delete("/routers/$id");
    return 1;
}

sub add_router_interface {
    my ($self, $id, $subnet_id) = @_;
    throw Net::OpenStack::Exception("The router id is needed") unless $id;
    throw Net::OpenStack::Exception("subnet id is required") unless $subnet_id;
    my $res = $self->_put("/routers/$id/add_router_interface", { subnet_id => $subnet_id });
    return undef unless $res->is_success;
    return from_json($res->content)->{port_id};
}

sub remove_router_interface {
    my ($self, $id, $port_id) = @_;
    throw Net::OpenStack::Exception("The router id is needed") unless $id;
    throw Net::OpenStack::Exception("port id is required") unless $port_id;
    my $res = $self->_put("/routers/$id/remove_router_interface", { port_id => $port_id });
    return $res->is_success;
}

sub remove_router_interface_by_subnet {
    my ($self, $id, $subnet_id) = @_;
    throw Net::OpenStack::Exception("The router id is needed") unless $id;
    throw Net::OpenStack::Exception("subnet id is required") unless $subnet_id;
    my $res = $self->_put("/routers/$id/remove_router_interface", { subnet_id => $subnet_id });
    return $res->is_success;
}

# Internal methods

sub _url {
    my ($self, $path, $is_detail, $query) = @_;
    my $url = $self->base_url . $path;
    $url .= '/detail' if $is_detail;
    $url .= $query if $query;
    return $url;
}

sub _get {
    my ($self, $url) = @_;
    return $self->_agent->get($self->_url($url));
}

sub _post {
    my ($self, $url, $data) = @_;
    return $self->_agent->post(
        $self->_url($url),
        content_type => 'application/json',
        content      => to_json($data),
    );
}

sub _put {
    my ($self, $url, $data) = @_;
    return $self->_agent->put(
        $self->_url($url),
        content_type => 'application/json',
        content      => to_json($data),
    );
}

sub _delete {
    my ($self, $url) = @_;
    my $req = HTTP::Request->new(DELETE => $self->_url($url));
    return $self->_agent->request($req);
}

sub _check_res {
    my ($res) = @_;
    throw Net::OpenStack::Exception($res->status_line . "\n" . $res->content)
        if ! $res->is_success and $res->code != 404;
    return 1;
}

around qw( _get _post _put _delete ) => sub {
    my $orig = shift;
    my $self = shift;
    my $res = $self->$orig(@_);
    _check_res($res);
    return $res;
};

1;
