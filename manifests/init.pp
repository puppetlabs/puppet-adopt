class adopter{

  $gems = ['inquirer','puppetclassify']
  package { $gems,
    ensure   => installed,
    provider => 'pe_gem',
  }
}
