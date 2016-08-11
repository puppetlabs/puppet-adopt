require 'puppet/face'
require 'puppet/forge'
require 'puppet/module_tool/install_directory'
require 'puppet_x/adopter'
require 'inquirer'

Puppet::Face.define(:adopter, '0.0.1') do

  action(:module) do

    summary 'Run module adoption workflow'

    description <<-EOT
      Fill this in later!
    EOT

    examples <<-EOT
      Adopt a new module:

      $ puppet adopter module puppetlabs-ntp
      ... stuff happens!
    EOT

    arguments '<name>'

    option '--target_dir DIR', '-i DIR' do
      summary 'Target Directory for module installation.'
      description <<-EOT
        This tells you how this works
      EOT
    end

    when_invoked do |name, options|
      Puppet.notice "Preparing to run experiment for module '#{name}'"
      Puppet.notice 'Installing Modules...'

      module_face = Puppet::Interface[:module, :current]
      install_result = module_face.install(name,{target_dir: options[:target_dir]})

      if install_result[:result] == :noop
        Puppet.notice "Module #{name} #{install_result[:version]} is already installed."
      else
        module_face.install_when_rendering_console(install_result, name,  {})
      end

      simple_name = name.split('-').last
      group_name = "Adopter Experiment: #{simple_name}"
      group = PuppetX::Adopter::NodeGroup.new(group_name, simple_name)

      # Refreshes the console cache is the default class isn't found after fresh module install
      if install_result[:result] != :noop and not group.default_class_exists_on_console?
        Puppet.notice "Default class \"#{simple_name}\" not found, reloading Enterprise Console cache..."
        PuppetX::Adopter::Util.run_with_spinner(60) { group.reload_console_cache }
      end
      use_class = group.default_class_exists_on_console?

      # Make sure the correct group exists
      if group.exists?
        if Ask.confirm "Group \"#{group_name}\" currently exists, use existing group?"
          Puppet.notice 'Using existing group'
          create_group = false
        else
          Puppet.notice 'Recreating group...'
          group.destroy
          create_group = true
        end
      else
        Puppet.notice 'Creating new group for experiment...'
        create_group = true
      end

      if create_group
        group.create(use_class)
        unless use_class
          Puppet.notice "No class named \"#{simple_name}\" found, you need to add the correct class or classes to this group manually."
        end
        Puppet.notice "Check classification for \"#{group_name}\" in the Enterprise Console before continuing"
        Puppet.notice "Navigate a browser to https://#{PuppetX::Adopter::Client.nc_config['hostname']}/#/node_groups/groups/#{group.id}"
        Ask.input 'When you are ready, press enter to continue'
        group.reload
      end

      Puppet.notice 'Starting Puppet Agent runs on experiment population'
      runner = PuppetX::Adopter::Runner.new(group)
      completed = runner.run(120)

      Puppet.notice 'Puppet Agent runs completed'
      if completed.count != group.node_count
        Puppet.notice "Only #{completed.count} nodes of #{group.node_count} nodes in group completed a Puppet Agent in time provided"
      end
      # Run all nodes in group using PCP?

      processor = PuppetX::Adopter::Processor.new(group)
      processor.process

      # Logic to figure out if it worked correctly

      processor

    end

    when_rendering :console do |processor, name, options|
      output = Array.new
      output << "\n"
      output << "Total Variations Discovered: #{processor.variations.count}\n"

      count = 1
      processor.variations.each do |events, nodes|
        output << "Variation #{count}"
        output << "    Total Events: #{events.count}"
        output << "    Total Nodes:  #{nodes.count}"
        output << "---\n"

        events.each do |event|
          output << "Event - #{event['resource_type']}[#{event['resource_title']}]"
          output << "    Proporty:  #{event['property']}"
          output << "    Old Value: #{event['old_value']}"
          output << "    NewValue:  #{event['new_value']}"
          output << "    Message:  #{event['message']}"
          output << '---'
        end

        output << 'Nodes:'
        nodes.each do |node|
          output << "    #{node.name}"
        end
        output << "-----------------END VARIATION #{count}-------------"

        count +=1
      end
      output.join("\n")
    end
  end

end
