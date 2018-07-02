shared_examples 'configurable clock_type' do
  it "should have configurable field clock_type" do
    # defaults to 24h format
    expect(subject.clock_type).to eq '24h'
    expect(subject.time_format).to eq :time24

    subject.clock_type = '12h'
    expect(subject.clock_type).to eq '12h'
    expect(subject.time_format).to eq :time12
  end
end
