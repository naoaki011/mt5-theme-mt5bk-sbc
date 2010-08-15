#
# Get Query Param
# 2005/10/24 1.00 First Release
# 2006/08/16 1.01 Modified
# 2007/01/03 1.02 Modified
# 2007/01/09 1.10 Add several tags
# 2007/02/18 1.11 Add GetParamID tag
# 2008/01/13 1.12 For Movable Type 4.x
# 2008/12/22 1.13 Add several tags
#
# Copyright(c) by H.Fujimoto
#
package MT::Plugin::GetQueryParam;

use MT;
use base qw(MT::Plugin);

use strict;

use MT::Template::Context;
use MT::Plugin;
use MT::Util qw( encode_url start_end_year start_end_month
                 start_end_week start_end_day);

# show plugin information to main menu
my $plugin = MT::Plugin::GetQueryParam->new({
    name => 'Get Query Param',
    version => '1.13',
    author_name => '<__trans phrase="Hajime Fujimoto">',
    author_link => 'http://www.h-fj.com/blog/',
    description => '<__trans phrase="Process query parameter value of get/post method.">',
    l10n_class => 'GetQueryParam::L10N',
});
MT->add_plugin($plugin);

# init_registry
sub init_registry
{
    my $plugin = shift;

    $plugin->registry({
        tags => {
            function => {
                'GetQueryParamsToVars' => \&get_query_params_to_vars,
                'GetQueryParam' => \&get_query_param,
                'GetQueryParamDateToVar' => \&get_query_param_date_to_var,
                'GetParamValue' => \&get_param_value,
                'GetParamString' => \&get_param_string,
                'GetParamID' => \&get_param_id,
                'GetParamStringFromValue' => \&get_param_string_from_value,
                'GetParamValueFromString' => \&get_param_value_from_string,
            },
            block => {
                'GetQueryParams' => \&get_query_params,
                'IfQueryParam?' => \&if_query_param,
                'SetParamList' => \&set_param_list,
                'GetParamList' => \&get_param_list,
                'GetParamListHeader?' => \&get_param_list_header,
                'GetParamListFooter?' => \&get_param_list_footer,
                'IfParamValue?' => \&if_param_value,
            },
        }
    });
}

# MTGetQueryParamsToVars {
sub get_query_params_to_vars {
    my ($ctx, $args) = @_;
    my $app = MT->instance;

    my @fields;
    my $fields = $args->{name};
    if ($fields) {
        @fields = split /\s*,\s/, $fields;
    }
    else {
        @fields = $app->param;
    }
    my $prefix = $args->{prefix} || 'qp_';
    my $delim = $args->{delimiter} || ',';
    my $a_suffix = $args->{a_suffix} || '_a';
    my $h_suffix = $args->{h_suffix} || '_h';
    my $l_suffix = $args->{l_suffix} || '_l';
    my $vars = $ctx->{__stash}{vars} ||= {};
    for my $field (@fields) {
        my @params = $app->param($field);
        $vars->{$prefix . $field} = join $delim, @params;
        $vars->{$prefix . $field . $a_suffix} = \@params;
        my %params;
        map { $params{$_} = 1; } @params;
        $vars->{$prefix . $field . $h_suffix} = \%params;
        $vars->{$prefix . $field . $l_suffix} = scalar @params;
    }
    '';
}

# MTGetQueryParam tag
sub get_query_param {
    my ($ctx, $args) = @_;

    my $value;
    if ($ctx->stash('gqp_query_params_name')) {
        $value = $ctx->stash('gqp_query_params_value');
    }
    else {
        my $app = MT->instance;
        $value = $app->param($args->{'name'}) || '';
    }
    $value;
}

# MTGetQueryParamDateToVar tag
sub get_query_param_date_to_var {
    my ($ctx, $args) = @_;

    my $app = MT->instance;
    my $field = $args->{name} || $args->{field}
        or return '';
    my ($ye, $mo, $da, $ho, $mi, $se, $ts);
    my %func = (
        'year' => \&start_end_year,
        'month' => \&start_end_month,
        'week' => \&start_end_week,
        'day' => \&start_end_day,
        'hour' => \&start_end_hour,
        'minute' => \&start_end_min,
    );
    $ye = $app->param("${field}_year");
    $mo = $app->param("${field}_month");
    $da = $app->param("${field}_day");
    $ho = $app->param("${field}_hour");
    $mi = $app->param("${field}_minute");
    $se = $app->param("${field}_second");
    if ($ye eq '' || $mo eq '' || $da eq '' ||
               $ho eq '' || $mi eq '' || $se eq '') {
        $ts = '';
    }
    else {
        $ts = sprintf("%04d%02d%02d%02d%02d%02d", $ye, $mo, $da, $ho, $mi, $se);
        my $mode = $args->{start} || $args->{end};
        if ($mode) {
            my $func = $func{$mode} or return '';
            my ($start, $end) = $func->($ts);
            if ($args->{start}) {
                $ts = $start;
            }
            elsif ($args->{end}) {
                $ts = $end;
            }
        }
    }
    my $vars = $ctx->{__stash}{vars} ||= {};
    $vars->{"qp_${field}"} = $ts;
    '';
}


# MTIfQueryParam tag
sub if_query_param {
    my ($ctx, $args) = @_;

    my $app = MT->instance;
    my $value = $app->param($args->{'name'}) || '';
    my $comp = $args->{'value'};
    ($value eq $comp);
}

# MTGetQueryParams tag
sub get_query_params {
    my ($ctx, $args, $cond) = @_;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');

    my $app = MT->instance;
    my @values = $app->param($args->{name});
    my @res = ();
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    my $size = scalar @values;
    local $vars->{__size__} = $size;
    local $ctx->{__stash}{gqp_query_params_name} = $args->{name};
    for my $value (@values) {
        local $vars->{__first__} = !$i;
        local $vars->{__last__} = ($i == $size - 1);
        local $vars->{__odd__} = ($i % 2) == 0;
        local $vars->{__even__} = ($i % 2) == 1;
        local $vars->{__counter__} = $i + 1;
        local $ctx->{__stash}{gqp_query_params_value} = $value;
        defined(my $out = $builder->build($ctx, $tokens, $cond))
           or return $ctx->error($builder->errstr);
        push @res, $out;
        $i++;
    }
    join $args->{glue}, @res;
}

# MTSetParamList tag
sub set_param_list {
    my ($ctx, $args, $cond) = @_;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');

    my $list_name = $args->{list_name}
        or return $ctx->error($plugin->translate('List name is not specified.'));
    my $list_str = $builder->build($ctx, $tokens, $cond)
        or return $ctx->error($plugin->translate('List is not defined.'));

    my $param_list = [];
    my $value_to_str_hash = {};
    my $str_to_value_hash = {};
    for my $tmp (split(/\r?\n/, $list_str)) {
        my @value_str = split '\|', $tmp;
        next if ($value_str[0] == '' && $value_str[1] eq '');
        push @$param_list, { value => $value_str[0],
                             string => $value_str[1],
                             id => $value_str[2] ? $value_str[2] : '' };
        $value_to_str_hash->{($value_str[0] eq '') ? '__value__null__' : $value_str[0]} = $value_str[1],
        $str_to_value_hash->{$value_str[1]} = $value_str[0];
    }
    $ctx->stash('gqp_param_list_' . $list_name, $param_list);
    $ctx->stash('gqp_param_value_str_' . $list_name, $value_to_str_hash);
    $ctx->stash('gqp_param_str_value_' . $list_name, $str_to_value_hash);
    '';
}

# MTGetParamList tag
sub get_param_list {
    my ($ctx, $args, $cond) = @_;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');

    my $list_name = $args->{list_name}
        or return $ctx->error($plugin->translate('List name is not specified.'));
    my $param_list = $ctx->stash('gqp_param_list_' . $list_name)
        or return $ctx->error($plugin->translate("List '[_1]' is not defined.", $list_name));

    my @res = ();
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    for my $param (@$param_list) {
        local $vars->{___first___} = !$i;
        local $vars->{___last___} = ($i == scalar(@$param_list) - 1);
        local $vars->{___odd___} = ($i % 2) == 0;
        local $vars->{___even___} = ($i % 2) == 1;
        local $vars->{___counter___} = $i + 1;
        local $vars->{gp_value} = $param->{value};
        local $vars->{gp_string} = $param->{string};
        local $vars->{gp_id} = $param->{id};
        $ctx->stash('gqp_query_param_value', $param->{value});
        $ctx->stash('gqp_query_param_string', $param->{string});
        $ctx->stash('gqp_query_param_id', $param->{id});
        $ctx->stash('gqp_query_param_header', ($i == 0));
        $ctx->stash('gqp_query_param_footer', ($i == scalar(@$param_list) - 1));

        defined(my $out = $builder->build($ctx, $tokens, $cond))
           or return $ctx->error($builder->errstr);
        push @res, $out;
        $i++;
    }
    join $args->{glue}, @res;
}

# MTGetParamValue tag
sub get_param_value {
    my ($ctx, $args) = @_;

    $ctx->stash('gqp_query_param_value');
}

# MTGetParamString tag
sub get_param_string {
    my ($ctx, $args) = @_;

    $ctx->stash('gqp_query_param_string');
}

# MTGetParamID tag
sub get_param_id {
    my ($ctx, $args) = @_;

    $ctx->stash('gqp_query_param_id');
}

# MTGetParamValueFromString tag
sub get_param_value_from_string {
    my ($ctx, $args) = @_;

    my $list_name = $args->{list_name}
        or return $ctx->error($plugin->translate('List name is not specified.'));
    my $hash = $ctx->stash('gqp_param_str_value_' . $list_name)
        or return $ctx->error($plugin->translate("List '[_1]' is not defined.", $list_name));
    $hash->{$args->{string}} || '';
}

# MTGetParamStringFromValue tag
sub get_param_string_from_value {
    my ($ctx, $args) = @_;

    my $list_name = $args->{list_name}
        or return $ctx->error($plugin->translate('List name is not specified.'));
    my $hash = $ctx->stash('gqp_param_value_str_' . $list_name)
        or return $ctx->error($plugin->translate("List '[_1]' is not defined.", $list_name));
    my $value = $args->{value};
    $value = '__value__null__' if ($value eq '');
    $hash->{$value} || '';
}

# MTGetParamListHeader tag
sub get_param_list_header {
    my ($ctx, $args) = @_;

    $ctx->stash('gqp_query_param_header');
}

# MTGetParamListHeader tag
sub get_param_list_footer {
    my ($ctx, $args) = @_;

    $ctx->stash('gqp_query_param_footer');
}

# MTIfParamValue tag
sub if_param_value {
    my ($ctx, $args) = @_;
    my $app = MT->instance;

    my $param_name = $args->{param_name};
    my $comp_value = $args->{comp_value};
    if (!$param_name && !$comp_value) {
        return $ctx->error('Parameter name or compare value is not specified.');
    }
    my $src = $ctx->stash('gqp_query_param_value');
    my $dst = $param_name ? $app->param($param_name)
                          : $comp_value;
    ($src eq $dst);
}

sub start_end_hour {
    my $hour = substr $_[0], 0, 10;
    return $hour . '0000' unless wantarray;
    return ("${hour}0000", "${hour}5959");
}

sub start_end_minute {
    my $min = substr $_[0], 0, 12;
    return $min . '00' unless wantarray;
    return ("${min}00", "${min}59");
}

1;
