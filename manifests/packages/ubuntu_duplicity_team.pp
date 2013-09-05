class duplicity::packages::ubuntu_duplicity_team {

  if ! defined ('python-software-properties') {
      package { 'python-software-properties':
          ensure => installed,
      }
  }

  exec { '/usr/bin/add-apt-repository -y ppa:duplicity-team/ppa':
    creates => "/etc/apt/sources.list.d/duplicity-team-ppa-${::lsbdistcodename}.list",
    require => Package[ 'python-software-properties' ]
  }

  exec { 'duplicity-team-update':
    command     => "/usr/bin/apt-get update",
    require     => Exec[ '/usr/bin/add-apt-repository -y ppa:duplicity-team/ppa' ],
    refreshonly => true,
  }

  $duplicity_version = "0.6.21-0ubuntu0ppa21~${::lsbdistcodename}1"

  Package <| title == 'duplicity' |> {
    ensure  => $duplicity_version,
    require => Exec[ 'duplicity-team-update' ],
  }

}

