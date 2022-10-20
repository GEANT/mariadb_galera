Facter.add('galera4_gcc_exist') do
  setcode do
    if File.file?('/usr/bin/gcc')
      true
    else
      false
    end
  end
end
