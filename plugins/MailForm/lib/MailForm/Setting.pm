package MailForm::Setting;

use strict;

use MT::Object;
@MailForm::Setting::ISA = qw(MT::Object);
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer not null',
        'author_id' => 'integer',
        'title' => 'string(255)',
        'description' => 'text',
        'email_to' => 'string(255)',
        'email_to2' => 'text',
        'email_cc' => 'text',
        'email_bcc' => 'text',
        'email_from' => 'string(255)',
        'email_from_type' => 'integer',
        'mail_subject' => 'string(255)',
        'form_template_id' => 'integer',
        'preview_template_id' => 'integer',
        'error_template_id' => 'integer',
        'post_template_id' => 'integer',
        'common_template_id' => 'integer',
        'body_template_id' => 'integer',
        'auto_reply' => 'boolean',
        'rmail_from' => 'string(255)',
        'reply_subject' => 'string(255)',
        'reply_template_id' => 'integer',
        'error_check_fields' => 'text',
        'error_specific_check' => 'text',
        'must_check_fields' => 'text',
        'email_confirm' => 'boolean',
        'error_check_in_preview' => 'boolean',
        'use_ajax' => 'boolean',
        'wait_msg' => 'text',
        'error_msg' => 'text',
    },
    indexes => {
        blog_id => 1,
        title => 1,
    },
    child_of => 'MT::Blog',
    datasource => 'mailform_setting',
    primary_key => 'id',
    class_type => 'mailform_setting',
});

1;
