# Install and manage the r10k gem
#
# @param client_remote the git remote address to bring code from, in the format
# 'git@git.server.com:git_group/control_repo_git_project.git'. If not defined,
# only the Puppet controlrepo source will be configured.
#
# @param webhook_port the port number where the server will listen to receive
# controlrepo updates. Default to 8088
#
# [Remember: No empty lines between comments and class definition]
class profiles::puppet::r10k (
  Optional[String] $client_remote = undef,
  Integer          $webhook_port  = 8088,
) {

  include profiles::linux::firewall

  firewalld_port { 'Open r10k webhook port in the public zone':
    ensure   => present,
    zone     => 'public',
    port     => $webhook_port,
    protocol => 'tcp',
  }

  $puppet_controlrepo_source = {
    'puppet' => {
      'remote'  => 'https://github.com/instruct-br/puppet-controlrepo.git',
      'basedir' => '/etc/puppetlabs/code/environments',
      'prefix'  => true,
    }
  }

  $client_controlrepo_source = {
    'client' => {
      'remote'  => $client_remote,
      'basedir' => '/etc/puppetlabs/code/environments',
      'prefix'  => false,
    }
  }

  if $client_remote {
    $real_sources = $puppet_controlrepo_source + $client_controlrepo_source
  } else {
    $real_sources = $puppet_controlrepo_source
  }

  class { 'r10k':
    sources => $real_sources
  }

  class { 'r10k::webhook::config':
    enable_ssl      => false,
    protected       => false,
    use_mcollective => false,
    port            => $webhook_port,
  }

  class { 'r10k::webhook':
    use_mcollective => false,
    user            => 'root', # FIXME change to puppet user
    group           => 'root', # FIXME change to puppet group
    require         => [
      Class['r10k::webhook::config'],
    ],
  }

}
