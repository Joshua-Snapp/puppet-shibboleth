# This generates a self signed x509 certificate used to secure connections
# with a Shibboleth Federation registry. If the key is ever lost or overwritten
# the certificate will have to be re-registered.
# Alternativly, the certificate could be deployed from the puppetmaster
class shibboleth::backend_cert(
  $entityid               = $shibboleth::entityid,
  $hostname               = $shibboleth::hostname,
  $cert_validity_duration = $shibboleth::cert_validity_duration,
) inherits shibboleth::params {

  require ::shibboleth

  if $entityid {
    $entityid_split = split($entityid, '/')
    $sp_hostname       = $entityid_split[0]
  }
  else {
    $sp_hostname = $hostname
  }

  $sp_cert_file = "${::shibboleth::conf_dir}/${::shibboleth::sp_cert}"

  if $::osfamily == 'Debian' {
    $keygen_command = 'shib-keygen'
  }

  if $::osfamily == 'RedHat' {
    $keygen_command = 'keygen.sh'
  }

  exec{"shib_keygen_${sp_hostname}":
    path    => [$::shibboleth::bin_dir,'/usr/bin','/bin'],
    command => "${keygen_command} -f -u ${::shibboleth::user} -g ${::shibboleth::group} -y ${cert_validity_duration} -h ${sp_hostname} -e https://${sp_hostname}/shibboleth -o ${::shibboleth::conf_dir}",
    unless  => "openssl x509 -noout -in ${sp_cert_file} -issuer|grep ${sp_hostname}",
  }
}
