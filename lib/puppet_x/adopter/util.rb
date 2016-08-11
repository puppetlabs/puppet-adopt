module PuppetX::Adopter::Util

  def self.run_with_spinner(timeout = 30, &block)

    spin_thread = Thread.new do
      loop do
        %w(| / - \\).each { |c| print c; sleep 0.1; print "\b" }
      end
    end

    Timeout::timeout(timeout) do
      return block.call
    end

  ensure
    spin_thread.terminate
    print "\n"
  end

end
