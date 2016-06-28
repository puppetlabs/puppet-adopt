require 'puppet/face'
require 'puppet/forge'
require 'puppet/module_tool/install_directory'
require 'puppet/adopter'
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

    option "--target_dir DIR", "-i DIR" do
      summary "Target Directory for module installation."
      description <<-EOT
        This tells you how this works
      EOT
    end

    option "--group_name NAME", "-g NAME" do
      summary "Name of exisiting group to use for experiment."
    end

    when_invoked do |name, options|

      Puppet.notice "Preparing to run exeriment for module '#{name}'"

      Puppet.notice "Installing Modules..."
      module_face = Puppet::Interface[:module, :current]
      install_result = module_face.install(name,{:target_dir => options[:target_dir]})

      if install_result[:result] == :noop
        Puppet.notice "Module #{name} #{install_result[:version]} is already installed."
      else
        module_face.install_when_rendering_console(install_result, name,  {})
      end

      simple_name = name.split('-').last
      group_name = options[:group_name] || "Adopter Experiment: #{simple_name}"

      group = Puppet::Adopter::NodeGroup.new(group_name)

      # eff this code, replace with some ruby
      if group.exists?
        if Ask.confirm "Group \"#{group_name}\" currently exists, use exisitng group?"
          Puppet.notice "Using exisiting group"
        else
          Puppet.notice "Recreating group..."
          group.destroy
          group.create(simple_name)
          Puppet.notice "Check classification for \"#{group_name}\" in the Enterprise Console before continuing"
          Puppet.notice "Navigate a browser to https://#{Puppet::Adopter::Client.nc_config['hostname']}/#/node_groups/groups/#{group.id}"
          Ask.input "When you are ready, press enter to continue"
          group.reload
        end
      else
        # this code doesn't work yet :)
        Puppet.notice "Creating new group for experiment..."
        group.create(simple_name)
        Puppet.notice "Check classification for \"#{group_name}\" in the Enterprise Console before continuing"
        Puppet.notice "Navigate a browser to https://#{Puppet::Adopter::Client.nc_config['hostname']}/#/node_groups/groups/#{group.id}"
        Ask.input "When you are ready, press enter to continue"
        group.reload
      end

      # Run all nodes in group using PCP?

      processor = Puppet::Adopter::Processor.new(group)
      processor.process

      # Logic to figure out if it worked correctly

      processor

    end

    when_rendering :console do |processor, name, options|
      Puppet.notice "Total Variations Discovered: #{processor.variations.count}\n"

      count = 1
      processor.variations.each do |events, nodes|
        Puppet.notice "Variation #{count}"
        Puppet.notice "    Total Events: #{events.count}"
        Puppet.notice "    Total Nodes:  #{nodes.count}"
        Puppet.notice "---\n"

        events.each do |event|
          Puppet.notice "Event - #{event['resource_type']}[#{event['resource_title']}]"
          Puppet.notice "    Old Value: #{event['old_value']}"
          Puppet.notice "    NewValue:  #{event['new_value']}"
          Puppet.notice "---"
        end

        Puppet.notice "Nodes:"
        nodes.each do |node|
          Puppet.notice "    #{node}"
        end
        Puppet.notice "-----------------END VARIATION #{count}-------------"

        count +=1
      end
    end
  end

end
