# Duplicity::Packages TODO: Write a good definition
class duplicity::packages {
  # Install the packages
  package {
    ['duplicity', 'python-boto', 'gnupg']: ensure => present
  }
}
