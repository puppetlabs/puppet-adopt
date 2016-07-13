class adopt{

  $puppet_gems = [
    'inquirer',
    'puppetclassify',
    'puppetdb-ruby',
    'pcp-client',
    'ruby-progressbar',
  ]

  package { $puppet_gems:
    ensure   => 'installed',
    provider => 'puppet_gem',
  }

  # Need to give a different title to avoid duplicate resource errors
  package { 'puppetclassify Puppetserver Install':
    ensure   => 'installed',
    name     => 'puppetclassify',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }

  pe_puppet_authorization::rule { 'adopter pxp commands':
    match_request_path         => '/pcp-broker/send',
    match_request_type         => 'path',
    match_request_query_params => {
      'message_type' => [
        'http://puppetlabs.com/rpc_non_blocking_request',
        'http://puppetlabs.com/rpc_blocking_request',
      ],
    },
    allow                      => [
      'pe-internal-dashboard',
      'pe-internal-orchestrator',
      $::trusted['certname'],
    ],
    sort_order                 => 300,
    path                       => '/etc/puppetlabs/orchestration-services/conf.d/authorization.conf',
    notify                     => Service['pe-orchestration-services'],
  }

}
