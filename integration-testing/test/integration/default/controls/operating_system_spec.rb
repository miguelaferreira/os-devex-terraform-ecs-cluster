control 'operating_system' do
  describe command('uname -a') do
    its('stdout') { should match (/amzn1.x86_64/) }
  end
end
