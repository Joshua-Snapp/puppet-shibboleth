# Defines a Shibboleth Single Sign On resource
define shibboleth::sso (
  $discoveryURL       = undef,
  $idpURL             = undef,
  $discovery_protocol = $::shibboleth::params::discovery_protocol,
  $ecp_support        = false
){

  if $discoveryURL and $idpURL {
    fail('shibboleth::sso must have one of discoveryURL or idpURL set, not both.')
  } elsif !$discoveryURL and !$idpURL {
    fail('shibboleth::sso must have one of discoveryURL or idpURL set, not neither.')
  } else {

    if $idpURL {
      $entityID_aug = "set SSO/#attribute/entityID ${idpURL}"
    } else {
      $entityID_aug = 'rm SSO/#attribute/entityID'
    }

    if $discoveryURL {
      $discoveryURL_aug = [
        "set SSO/#attribute/discoveryURL ${discoveryURL}",
        "set SSO/#attribute/discoveryProtocol ${discovery_protocol}",
        ]
    } else {
      $discoveryURL_aug = [
      'rm SSO/#attribute/discoveryURL',
      'rm SSO/#attribute/discoveryProtocol',
      ]
    }

    augeas{"shib_sso_${name}_attributes":
      lens    => 'Xml.lns',
      incl    => $::shibboleth::config_file,
      context => "/files${::shibboleth::config_file}/SPConfig/ApplicationDefaults/Sessions",
      changes => flatten([
        $entityID_aug,
        $discoveryURL_aug,
        "set SSO/#attribute/ECP ${ecp_support}",
      ]),
      notify  => Service['httpd','shibd'],
    }
  }
}
