  def ensure_file_system_isolated(&)
    Dir.chdir(Dir.tmpdir, &)
  end

  def create_dir_with_one_mig
    Dir.mktmpdir do |path|
      migpath = Pathname(path).join('1')
      FileUtils.touch(migpath)
      yield path
    end
  end
