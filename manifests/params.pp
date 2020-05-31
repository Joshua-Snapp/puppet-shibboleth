# Class: shibboleth::params
#
# This class manages shared prameters and variables for the shibboleth module
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
class shibboleth::params {

  $admin                  = $::apache::serveradmin
  $cert_validity_duration = '10'
  $hostname               = $::fqdn
  $logo_location          = '/shibboleth-sp/logo.jpg'
  $style_sheet            = '/shibboleth-sp/main.css'
  $conf_dir               = '/etc/shibboleth'
  $conf_file              = 'shibboleth2.xml'
  $sp_cert                = 'sp-cert.pem'
  $discovery_protocol     = 'SAMLDS'
  $remote_user            = 'eppn persistent-id targeted-id'
  $handlerurl             = '/Shibboleth.sso'

  case $::osfamily {
    'Debian':{
      $bin_dir   = '/usr/sbin'
      $user      = '_shibd'
      $group     = '_shibd'
      $user_home = '/var/log/shibboleth'
    }
    'RedHat':{
      $bin_dir   = '/etc/shibboleth'
      $user      = 'shibd'
      $group     = 'shibd'
      $user_home = '/var/run/shibboleth'
    }
    default:{
      fail("The shibboleth Puppet module does not support ${::osfamily} family of operating systems")
    }
  }
}
