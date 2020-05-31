# Currently this only creates a _single_ metadata provider
# it will need to be modified to permit multiple metadata providers
define shibboleth::metadata(
  $provider_uri,
  $cert_uri                              = undef,
  $cert_dir                              = $::shibboleth::conf_dir,
  $provider_type                         = 'XML',
  $provider_reload_interval              = '7200',
  $metadata_filter_max_validity_interval = 2419200,
  $transportoption_option                = undef,
  $transportoption_provider              = undef,
  $transportoption_text                  = undef,
){


  if $cert_uri {
    # Get the Metadata signing certificate
    $cert_file_name = split($cert_uri, '/')
    $cert_file      = $cert_file_name[-1]
    exec{"get_${name}_metadata_cert":
      path    => ['/usr/bin'],
      command => "wget ${cert_uri} -O ${cert_dir}/${cert_file}",
      creates => "${cert_dir}/${cert_file}",
      notify  => Service['httpd','shibd'],
      before  => Augeas["shib_${name}_create_metadata_provider"]
    }

    $aug_signature = [
      'set MetadataProvider/MetadataFilter[1]/#attribute/type Signature',
      "set MetadataProvider/MetadataFilter[1]/#attribute/certificate ${cert_file}",
    ]
  } else {
    $aug_signature = 'rm MetadataProvider/MetadataFilter[1]'
  }

  if $metadata_filter_max_validity_interval > 0 {
    $aug_valid_until = [
      'set MetadataProvider/MetadataFilter[2]/#attribute/type RequireValidUntil',
      "set MetadataProvider/MetadataFilter[2]/#attribute/maxValidityInterval ${metadata_filter_max_validity_interval}",
    ]
  } else {
    $aug_valid_until = 'rm MetadataProvider/MetadataFilter[2]'
  }

  # This puts the MetadataProvider entry in the 'right' place
  augeas{"shib_${name}_create_metadata_provider":
    lens    => 'Xml.lns',
    incl    => $::shibboleth::config_file,
    context => "/files${::shibboleth::config_file}/SPConfig/ApplicationDefaults",
    changes => [
      'ins MetadataProvider after Errors',
    ],
    onlyif  => 'match MetadataProvider/#attribute/uri size == 0',
    notify  => Service['httpd','shibd'],
  }

  # This will update the attributes and child nodes if they change
  $backing_file_name = split($provider_uri, '/')
  $backing_file = $backing_file_name[-1]
  augeas{"shib_${name}_metadata_provider":
    lens    => 'Xml.lns',
    incl    => $::shibboleth::config_file,
    context => "/files${::shibboleth::config_file}/SPConfig/ApplicationDefaults",
    changes => flatten(
      [
        "set MetadataProvider/#attribute/type ${provider_type}",
        "set MetadataProvider/#attribute/uri ${provider_uri}",
        "set MetadataProvider/#attribute/backingFilePath ${backing_file}",
        "set MetadataProvider/#attribute/reloadInterval ${provider_reload_interval}",
        $aug_valid_until,
        $aug_signature,
      ]
    ),
    notify  => Service['httpd','shibd'],
    require => [Augeas["shib_${name}_create_metadata_provider"]],
  }

  if $transportoption_provider and $transportoption_option and $transportoption_text {
    $transportoption_aug = [
      "set TransportOption/#attribute/provider ${transportoption_provider}",
      "set TransportOption/#attribute/option ${transportoption_option}",
      "set TransportOption/#text ${transportoption_text}",
    ]
  }
  else {
    $transportoption_aug = 'rm TransportOption'
  }

  augeas{"shib_${name}_metadata_provider_transport_option":
    lens    => 'Xml.lns',
    incl    => $::shibboleth::config_file,
    context => "/files${::shibboleth::config_file}/SPConfig/ApplicationDefaults/MetadataProvider",
    changes => $transportoption_aug,
    notify  => Service['httpd','shibd'],
    require => Augeas["shib_${name}_metadata_provider"],
  }
}
