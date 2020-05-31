# Class: shibboleth
#
# This module manages shibboleth
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

# [Remember: No empty lines between comments and class definition]
class shibboleth (
  $admin                  = $::shibboleth::params::admin,
  $cert_validity_duration = $::shibboleth::params::cert_validity_duration,
  $entityid               = $::shibboleth::params::entityid,
  $hostname               = $::shibboleth::params::hostname,
  $user                   = $::shibboleth::params::user,
  $user_home              = $::shibboleth::params::user_home,
  $group                  = $::shibboleth::params::group,
  $logo_location          = $::shibboleth::params::logo_location,
  $style_sheet            = $::shibboleth::params::style_sheet,
  $conf_dir               = $::shibboleth::params::conf_dir,
  $conf_file              = $::shibboleth::params::conf_file,
  $sp_cert                = $::shibboleth::params::sp_cert,
  $bin_dir                = $::shibboleth::params::bin_dir,
  $ciphersuites           = undef,
  $signing                = undef,
  $encryption             = undef,
  $remote_user            = $::shibboleth::params::remote_user,
  $handlerurl             = $::shibboleth::params::handlerurl,
  $handlerSSL             = true,
  $consistent_address     = true
) inherits shibboleth::params {

  $config_file = "${conf_dir}/${conf_file}"

  user{$user:
    ensure  => 'present',
    home    => $user_home,
    shell   => '/bin/false',
    require => Class['apache::mod::shib'],
  }

  # by requiring the apache::mod::shib, these should wait for the package
  # to create the directory.
  file{'shibboleth_conf_dir':
    ensure  => 'directory',
    path    => $conf_dir,
    owner   => $user,
    group   => $group,
    recurse => true,
    require => Class['apache::mod::shib'],
  }

  file{'shibboleth_config_file':
    ensure  => 'file',
    path    => $config_file,
    replace => false,
    require => [Class['apache::mod::shib'],File['shibboleth_conf_dir']],
  }

# Using augeas is a performance hit, but it works. Fix later.
  augeas{'sp_config_resources':
    lens    => 'Xml.lns',
    incl    => $config_file,
    context => "/files${config_file}/SPConfig/ApplicationDefaults",
    changes => [
      "set Errors/#attribute/supportContact ${admin}",
      "set Errors/#attribute/logoLocation ${logo_location}",
      "set Errors/#attribute/styleSheet ${style_sheet}",
    ],
    notify  => Service['httpd','shibd'],
    require => File['shibboleth_config_file'],
  }

  augeas{'sp_config_consistent_address':
    lens    => 'Xml.lns',
    incl    => $config_file,
    context => "/files${config_file}/SPConfig/ApplicationDefaults",
    changes => [
      "set Sessions/#attribute/consistentAddress ${consistent_address}",
    ],
    notify  => Service['httpd','shibd'],
    require => File['shibboleth_config_file'],
  }

  if $signing {
    $signing_aug = "set #attribute/signing ${signing}"
  } else {
    $signing_aug = 'rm #attribute/signing'
  }

  if $encryption {
    $encryption_aug = "set #attribute/encryption ${encryption}"
  } else {
    $encryption_aug = 'rm #attribute/encryption'
  }

  if $ciphersuites {
    $ciphersuites_aug = "set #attribute/cipherSuites ${ciphersuites}"
  } else {
    $ciphersuites_aug = 'rm #attribute/cipherSuites'
  }

  if $entityid {
    $sp_config_entityid_aug = "set #attribute/entityID https://${entityid}"
  }
  else {
    $sp_config_entityid_aug = "set #attribute/entityID https://${hostname}/shibboleth"
  }


  augeas{'sp_config_entityid':
    lens    => 'Xml.lns',
    incl    => $config_file,
    context => "/files${config_file}/SPConfig/ApplicationDefaults",
    changes => flatten([
      $sp_config_entityid_aug,
      $signing_aug,
      $encryption_aug,
      "set #attribute/REMOTE_USER \"${remote_user}\"",
      $ciphersuites_aug,
      "set Sessions/#attribute/handlerURL ${handlerurl}",
    ]),
    notify  => Service['httpd','shibd'],
    require => File['shibboleth_config_file'],
  }

  $cookieProps = $handlerSSL ? {
    true      => 'https',
    default   => 'http',
  }

  augeas{'sp_config_handlerSSL':
    lens    => 'Xml.lns',
    incl    => $config_file,
    context => "/files${config_file}/SPConfig/ApplicationDefaults",
    changes => [
      "set Sessions/#attribute/handlerSSL ${handlerSSL}",
      "set Sessions/#attribute/cookieProps ${cookieProps}",
    ],
    notify  => Service['httpd','shibd'],
    require => File['shibboleth_config_file'],
  }

  service{'shibd':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [Class['apache::mod::shib'],User[$user],
    File['shibboleth_config_file']],
  }

}
