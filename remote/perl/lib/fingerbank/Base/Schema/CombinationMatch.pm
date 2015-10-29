package fingerbank::Base::Schema::CombinationMatch;

use Moose;
use namespace::autoclean;

extends 'fingerbank::Base::Schema';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('combinationmatch');

__PACKAGE__->add_columns(
    "id",
    "score",
    "dhcp_fingerprint_id",
    "dhcp_vendor_id",
    "user_agent_id",
    "mac_vendor_id",
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->result_source_instance->is_virtual(1);

# $1 = dhcp_fingerprint
# $2 = dhcp_vendor
# $3 = user_agent
# $4 = mac_vendor
__PACKAGE__->result_source_instance->view_definition(q{
    SELECT * FROM combination
    WHERE dhcp_fingerprint_id = $1 OR dhcp_vendor_id = $2 OR user_agent_id = $3 OR (mac_vendor_id = $4 OR mac_vendor_id IS NULL)
    ORDER BY
    case when (dhcp_fingerprint_id = $1 AND dhcp_fingerprint_id != '0') OR ( $1 = 0 AND dhcp_fingerprint_id = 0 )then 2 else 0 END +
    case when (dhcp_vendor_id = $2 AND dhcp_vendor_id != '0') OR ( $2 = '0' AND dhcp_vendor_id = '0')then 2 else 0 END +
    case when (user_agent_id = $3 AND user_agent_id != '0') OR ($3 = '0' AND user_agent_id = '0') then 2 else 0 END +
    case when (mac_vendor_id = $4 OR (mac_vendor_id IS NULL AND $4 IS NULL)) then 1 else 0 END
    DESC,
    score DESC LIMIT 1
});

__PACKAGE__->meta->make_immutable;

1;
