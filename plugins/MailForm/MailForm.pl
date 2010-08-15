#
# MailForm.pl
# 2006/03/05 1.00 First Release
# 2006/06/14 1.10 Version up
# 2006/10/18 1.11 For Ajax
# 2007/01/23 1.20 Version up
# 2007/01/27 1.20.1 Bug fix(XSS)
# 2007/08/26 1.30.1 Bug Fix
# 2008/01/09 2.00 Renewal
# 2008/06/24 2.10 For Movable Type 4.2
# 2008/08/08 2.10b Bug fix
# 2009/09/25 2.20beta1 For Movable Type 5
#
# Copyright(c) by H.Fujimoto
#
package MT::Plugin::MailForm;
use base 'MT::Plugin';

use strict;

use MT;
use MT::Template::Context;
use MT::Plugin;
use MT::Util qw( html_text_transform encode_html encode_js );
use MT::I18N;
use MailForm::Setting;

# show plugin information to main menu
my $plugin = MT::Plugin::MailForm->new({
    id => 'mailform',
    name => 'Mail Form',
    version => '2.20',
    author_name => "<__trans phrase=\"Hajime Fujimoto\">",
    author_link => 'http://www.h-fj.com/blog/',
    doc_link => 'http://www.h-fj.com/blog/mt5plgdoc/mailformv2_2.php',
    description => "<__trans phrase=\"This plugin allows you to create mail form by Movable Type template.\">",
    blog_config_template => \&mf_blog_config_template,
    l10n_class => 'MailForm::L10N',
    schema_version => '1.01',
});
MT->add_plugin($plugin);

# init_registry
sub init_registry
{
    my $plugin = shift;

#    my $label = $plugin->translate_templatized('Mail Form');
    $plugin->registry({
        tags => {
            function => {
                'MailPreviewAuthor' => \&mail_preview_author,
                'MailPreviewEMail' => \&mail_preview_email,
                'MailPreviewEMailConfirm' => \&mail_preview_email_confirm,
                'MailPreviewSubject' => \&mail_preview_subject,
                'MailPreviewBody' => \&mail_preview_body,
                'MailPreviewExtParam' => \&mail_preview_ext_param,
                'MailFormAjaxJS' => \&mail_form_ajax_js,
                'IncludeMailFormCommon' => \&include_mail_form_common,
            },
            block => {
                'MailPreviewIfError?' => \&mail_preview_if_error,
                'MailPreviewIfInputError?' => \&mail_preview_if_input_error,
                'MailPreviewIfFieldError?' => \&mail_preview_if_field_error,
                'MailPreviewIfEMailError?' => \&mail_preview_if_email_error,
                'MailPreviewIfEMailDifferent?' => \&mail_preview_if_email_different,
                'MailPreviewIfNotChecked?' => \&mail_preview_if_not_checked,
                'MailIfSendError?' => \&mail_if_send_error,
                'MailIfAutoReplyError?' => \&mail_if_auto_reply_error,
                'MailIfThrottled?' => \&mail_if_throttled,
                'MailIfIPBanned?' => \&mail_if_ipbanned,
                'MailIfSpam?' => \&mail_if_spam,
                'MailIfSystemTemplate?' => \&mail_if_system_template,
                'MailBodyContainer' => \&mail_body_container,
            },
        },
        object_types => {
            'mailform_setting' => 'MailForm::Setting',
        },
        applications => {
            'cms' => {
                'menus' => {
                    'mailform' => {
                        label => "Mail Form",
                        order => 750,
                    },
                    'mailform:manage' => {
                        label      => 'Manage',
                        mode       => 'fjmf_manage_setting',
                        order      => 100,
                        permission => 'administer_blog,administer_website',
                        view       => [ 'blog', 'website' ],
                    },
                    'mailform:create' => {
                        label      => 'New',
                        mode       => 'fjmf_do_setting',
                        order      => 200,
                        permission => 'administer_blog,administer_website',
                        view       => [ 'blog', 'website' ],
                    },
                    'mailform:sample_tmpl' => {
                        label      => 'Sample template',
                        mode       => 'fjmf_install_template_setup',
                        order      => 300,
                        permission => 'administer_blog,administer_website',
                        view       => [ 'blog', 'website' ],
                    },
                },
                'methods' => {
                    'fjmf_do_setting' =>
                        sub { runner('MailForm::DoSetting',
                                     'do_setting', @_); },
                    'fjmf_manage_setting' =>
                        sub { runner('MailForm::DoSetting',
                                     'list_setting', @_); },
                    'fjmf_save_setting' =>
                        sub { runner('MailForm::DoSetting',
                                     'save_setting', @_); },
                    'fjmf_insert_tag' =>
                        sub { runner('MailForm::DoSetting',
                                     'insert_tag', @_); },
                    'fjmf_rebuild' =>
                        sub { runner('MailForm::DoSetting',
                                     'rebuild', @_); },
                    'fjmf_install_template_setup' =>
                        sub { runner('MailForm::DoSetting',
                                     'install_template_setup', @_); },
                    'fjmf_install_template' =>
                        sub { runner('MailForm::DoSetting',
                                     'install_template', @_); },
                },
            },
        },
        callbacks => {
            'restore' =>
                sub { runner('MailForm::DoSetting',
                             'restore', @_); },
            'cms_post_delete.mailform_setting' =>
                sub { runner('MailForm::DoSetting',
                             'post_delete', @_); },
        },
        upgrade_functions => {
            'add_author_id_field' => {
                version_limit => '1.01',
                code => \&add_author_id_field,
            }
        },
    });
}

sub instance { $plugin };

# MTMailPreviewAuthor tag
sub mail_preview_author
{
    my ($ctx, $args) = @_;

    my $value = $ctx->stash('mail_author');
    $value = '' unless(defined($value));
    "$value";
}

# MTMailPreviewEMail tag
sub mail_preview_email
{
    my ($ctx, $args) = @_;

    my $value = $ctx->stash('mail_email');
    $value = '' unless(defined($value));
    "$value";
}

# MTMailPreviewEMailConfirm tag
sub mail_preview_email_confirm
{
    my ($ctx, $args) = @_;

    my $value = $ctx->stash('mail_email_confirm');
    $value = '' unless(defined($value));
    "$value";
}

# MTMailPreviewSubject tag
sub mail_preview_subject
{
    my ($ctx, $args) = @_;

    my $value = $ctx->stash('mail_subject');
    $value = '' unless(defined($value));
    "$value";
}

# MTMailPreviewBody tag
sub mail_preview_body
{
    my ($ctx, $args) = @_;

    my $value = $ctx->stash('mail_body');
    $value = '' unless(defined($value));
    if ($args->{convert_breaks} == 1) {
        $value = html_text_transform($value);
    }
    "$value";
}

# MTMailPreviewExtParam tag
sub mail_preview_ext_param
{
    my ($ctx, $args) = @_;

    my $ext_params = $ctx->stash('mail_ext_params');

    my $value = $ext_params->{$args->{name}};
    $value = '' unless(defined($value));
    if ($args->{convert_breaks} == 1) {
        $value = html_text_transform($value);
    }
    "$value";
}

# MTMailFormAjaxJS tag
sub mail_form_ajax_js
{
    my ($ctx, $args) = @_;

    my $builder = $ctx->stash('builder');
    my $setting = $ctx->stash('mail_setting');
    if (!$setting) {
        my $setting_title = $ctx->var('mail_setting');
        $setting = MailForm::Setting->load({ blog_id => $ctx->stash('blog_id'),
                                             title => $setting_title })
            or return $ctx->error($plugin->translate('Mail form setting load error'));
        $ctx->stash('mail_setting', $setting);
    }
    my $cgipath = $ctx->tag('CGIPath', $args);
    my $static_path = $ctx->tag('StaticWebPath', $args);
    my $wait_tok = $builder->compile($ctx, $setting->wait_msg);
    my $wait_msg = $builder->build($ctx, $wait_tok)
        or return $ctx->error($plugin->translate('Build error in wait message'));
    $wait_msg = encode_js($wait_msg);
    my $error_tok = $builder->compile($ctx, $setting->error_msg);
    my $error_msg = $builder->build($ctx, $error_tok)
        or return $ctx->error($plugin->translate('Build error in process error message'));
    $error_msg = encode_js($error_msg);
    my $out = '';
    if (!$args->{no_jquery}) {
        $out = <<HERE;
<script type="text/javascript" src="${static_path}jquery/jquery.js"></script>

HERE
    }
    $out .= <<HERE;
<script type="text/javascript" src="${static_path}plugins/MailForm/js/mailform.js"></script>
<script type="text/javascript">
//<![CDATA[
FJAjaxMail.cgiPath = '$cgipath';
FJAjaxMail.waitMsg = '$wait_msg';
FJAjaxMail.errorMsg = '$error_msg';
//]]>
</script>

HERE
    $out;
}

# MTMailPreviewIfEmailError tag
sub mail_preview_if_error
{
    my ($ctx, $args) = @_;


    $ctx->stash('is_mail_error') &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailPreviewIfInputError tag
sub mail_preview_if_input_error
{
    my ($ctx, $args) = @_;


    $ctx->stash('is_input_error') &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailPreviewIfFieldError tag
sub mail_preview_if_field_error
{
    my ($ctx, $args) = @_;

    my $error_fields = $ctx->stash('mail_error_fields');
    $error_fields->{$args->{name}} == 1 &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailPreviewIfEmailError tag
sub mail_preview_if_email_error
{
    my ($ctx, $args) = @_;

    $ctx->stash('is_mail_invalid') &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailPreviewIfEmailDifferent tag
sub mail_preview_if_email_different
{
    my ($ctx, $args) = @_;

    $ctx->stash('is_mail_different') &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailPreviewIfNotChecked tag
sub mail_preview_if_not_checked
{
    my ($ctx, $args) = @_;

    my $not_checked_fields = $ctx->stash('not_checked_fields');
    $not_checked_fields->{$args->{name}} == 1 &&
    ($ctx->var('mail_is_error_page') || $ctx->stash('mail_do_error_check'));
}

# MTMailIfAutoReplyError tag
sub mail_if_auto_reply_error
{
    my ($ctx, $args) = @_;

    return $ctx->stash('is_auto_reply_error');
}

# MTMailIfSendError tag
sub mail_if_send_error
{
    my ($ctx, $args) = @_;

    return $ctx->stash('is_send_error');
}

# MTMailIfThrottled tag
sub mail_if_throttled
{
    my ($ctx, $args) = @_;

    return $ctx->stash('is_throttled');
}

# MTMailIfIPBanned tag
sub mail_if_ipbanned
{
    my ($ctx, $args) = @_;

    return $ctx->stash('is_ipbanned');
}

# MTMailIfSpam tag
sub mail_if_spam
{
    my ($ctx, $args) = @_;

    return $ctx->stash('is_spam');
}

# MTMailIfSystemTemplate tag
sub mail_if_system_template
{
    my ($ctx, $args) = @_;

    return $ctx->stash('mail_is_system');
}

# MTMailBodyContainer tag
sub mail_body_container
{
    my ($ctx, $args, $cond) = @_;

    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');

    $ctx->stash('mail_unencode', 1);
    defined(my $body = $ctx->stash('builder')->build($ctx, $ctx->stash('tokens'), $cond))
        or return $ctx->error($builder->errstr);
    $ctx->stash('mail_unencode', undef);
    $body;
}

# MTMailErrors tag

# MTIncludeMailFormCommon tag
sub include_mail_form_common {
    my ($ctx, $args, $cond) = @_;

    my $setting = $ctx->stash('mail_setting');
    if (!$setting) {
        my $setting_title = $ctx->var('mail_setting');
        $setting = MailForm::Setting->load({ title => $setting_title })
            or return $ctx->error($plugin->translate('Mail form setting load error'));
        $ctx->stash('mail_setting', $setting);
    }
    my $common_tmpl_id = $setting->common_template_id;
    my $common_tmpl = MT::Template->load($common_tmpl_id);
    $args->{module} = $common_tmpl->name;
    my $out = $ctx->tag('Include', $args, $cond);
    $out;
}

sub runner {
    my $class = shift;
    my $method = shift;

    eval "require $class;";
    if ($@) { die $@; $@ = undef; return 1; }
    my $method_ref = $class->can($method);
    return $method_ref->($plugin, @_) if $method_ref;
    die $plugin->translate("Failed to find [_1]::[_2]", $class, $method);
}

# config template
sub mf_blog_config_template {
    my $app = MT->instance;
    my $blog_id = $app->param('blog_id');
    return <<HERE;
<div class="field field-left-label pkg">
<div class="field-header">
    <__trans phrase="Install Sample Mail Form Template">
</div>
<div class="field-content">
    <div class="actions-bar" style="clear : none;">
        <div class="actions-bar-inner pkg actions">
            <button
                type="submit"
                onclick="location.href='<mt:var name="script_uri">?__mode=fjmf_install_template_setup&amp;blog_id=${blog_id}'; return false;"
                accesskey="s"
                title="<__trans phrase="Install">"
                class="primary-button"
                style="color : white; font-weight : bold;"
                ><__trans phrase="Install"></button>
        </div>
    </div>
</div>
</div>
HERE
}

# upgrade function from 2.0 (schema version 1.0) to 2.1 (schema version 1.01)
sub add_author_id_field {
    my $plugin = shift;

    # load root user
    my $iter = MT::Author->load_iter({ type => MT::Author::AUTHOR() });
    my $author;
    while ($author = $iter->()) {
        last if (!$author->created_by);
    }
    die $plugin->translate('Can\'t find root user') if (!$author);

    # set user to mail form settings
    $iter = MailForm::Setting->load_iter;
    my $setting;
    while ($setting = $iter->()) {
        $setting->author_id($author->id);
        $setting->save or die $plugin->translate('Can\'t set user to mail form setting');
    }
}

1;
