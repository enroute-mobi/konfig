describe Konfig::YamlProvider do
  it "should read the yaml file" do
    expect { Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["test.yml"]) }.not_to raise_error
  end

  it "should fail with bad file" do
    expect { Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["bad_file.yml"]) }.to raise_error Konfig::FileNotFound
    expect { Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["bad_file.yml", "another_bad_file.yml"]) }.to raise_error Konfig::FileNotFound
  end

  it "should read development.yml by default" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"))
    expect(provider.files[0]).to end_with "development.yml"
  end

  it "should fetch a key" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["test.yml"])
    provider.load
    expect(provider.raw_settings.foo.bar.string).to eq "hello"
    expect(provider.raw_settings.foo.bar.number).to eq 2
    expect(provider.raw_settings.foo.bar.bool).to be_truthy
    expect(provider.raw_settings.foo.bar.nil).to be_nil

    expect(Settings.foo.bar.string).to eq "hello"
    expect(Settings.foo.bar.number).to eq 2
    expect(Settings.foo.bar.bool).to be_truthy
    expect(Settings.foo.bar.forced_string).to be_a_kind_of String
    expect(Settings.foo.bar.forced_string).to eq "12345.12345"
    expect(Settings.foo.bar.forced_string_with_quotes).to eq "12345.12345"
    expect(Settings.foo.bar.float).to be_a_kind_of Float
    expect(Settings.foo.bar.float).to eq 12345.12345
  end

  it "should parse erb" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["with_erb.yml"])
    provider.load
    expect(Settings.this.contains.erb).to eq 2
  end

  it "should handle bad keys" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["test.yml"])
    provider.load
    expect { Settings.foo.bar.bad_key }.to raise_error Konfig::KeyError
    expect { Settings.no_available }.to raise_error Konfig::KeyError
  end

  it "should work with hash objects" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["development.yml"])
    provider.load
    expect(Settings.other.things.are.even.better).not_to be_nil
    expect(Settings.other.things.are.even.better).to be_a_kind_of Array
    expect(Settings.other.things.are.even.better[0][:some]).to eq 1
    expect(Settings.other.things.are.even.better[0][:value]).to be_truthy
  end

  it "environment variable overrides should work" do
    ENV["KONFIG_SOME_THINGS_ARE_TOO_GOOD"] = "999"
    ENV["KONFIG_OTHER_THINGS_ARE_EVEN_BETTER"] = "[{ \"some\": 2, \"value\": true }]"

    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["development.yml"])
    provider.load
    expect(Settings.other.things.are.even.better).not_to be_nil
    expect(Settings.other.things.are.even.better).to be_a_kind_of Array
    expect(Settings.other.things.are.even.better[0][:some]).to eq 2
    expect(Settings.other.things.are.even.better[0][:value]).to be_truthy
    expect(Settings.some.things.are.too.good).to eq 999
  end

  it "should allow custom environment variable prefix" do
    Konfig.configuration.env_prefix = "CHANGED"
    ENV["CHANGED_SOME_THINGS_ARE_TOO_GOOD"] = "999"

    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["development.yml"])
    provider.load
    expect(Settings.some.things.are.too.good).to eq 999
  ensure
    Konfig.configuration.env_prefix = "KONFIG"
  end

  it "should ignore erb if forced" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["with_erb.yml"])
    provider.load(false)
    expect(Settings.this.contains.erb).to eq "<%= 1 + 1 %>"
  end

  it "should override" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["test.yml", "override.yml"])
    provider.load

    expect(Settings.foo.bar.string).to eq "goodbye"

    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["override.yml", "test.yml"])
    provider.load

    expect(Settings.foo.bar.string).to eq "hello"
  end

  it "should throw a useful error when the file is empty" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["empty.yml"])
    expect { provider.load }.to raise_error Konfig::FileError
  end

  it "should allow some missing files when more than one" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filenames: ["test.yml", "bad_file.yml"])
    expect { provider.load }.not_to raise_error
  end
end
