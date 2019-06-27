describe Konfig::YamlProvider do
  it "should read the yaml file" do
    expect { Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filename: "test.yml") }.not_to raise_error
  end

  it "should fail with bad file" do
    expect { Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filename: "bad_file.yml") }.to raise_error Konfig::FileNotFound
  end

  it "should read development.yml by default" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"))
    expect(provider.file).to end_with "development.yml"
  end

  it "should fetch a key" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filename: "test.yml")
    provider.load
    expect(provider.raw_settings.foo.bar.string).to eq "hello"
    expect(provider.raw_settings.foo.bar.number).to eq 2
    expect(provider.raw_settings.foo.bar.bool).to be_truthy
    expect(provider.raw_settings.foo.bar.nil).to be_nil

    expect(Settings.foo.bar.string).to eq "hello"
    expect(Settings.foo.bar.number).to eq 2
    expect(Settings.foo.bar.bool).to be_truthy
  end

  it "should parse erb" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filename: "with_erb.yml")
    provider.load
    expect(Settings.this.contains.erb).to eq 2
  end

  it "should handle bad keys" do
    provider = Konfig::YamlProvider.new(workdir: File.join(__dir__, "fixtures"), filename: "test.yml")
    provider.load
    expect { Settings.foo.bar.bad_key }.to raise_error NoMethodError
    expect { Settings.no_available }.to raise_error NoMethodError
  end
end