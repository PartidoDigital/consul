require 'rails_helper'

describe Ahoy::DataSource do

  describe '#build' do
    before :each do
      
      create :ahoy_event, name: 'foo', time: time_1
      create :ahoy_event, name: 'foo', time: time_1
      create :ahoy_event, name: 'foo', time: time_2
      create :ahoy_event, name: 'bar', time: time_1
      create :ahoy_event, name: 'bar', time: time_3
      create :ahoy_event, name: 'bar', time: time_3
    end

    it 'should work without data sources' do
      ds = Ahoy::DataSource.new
      expect(ds.build).to eq x: []
    end

    it 'should work with single data sources' do
      ds = Ahoy::DataSource.new
      ds.add 'foo', Ahoy::Event.where(name: 'foo').group_by_day(:time).count
      expect(ds.build).to eq :x => [time_1.strftime("%Y-%m-%d"), time_2.strftime("%Y-%m-%d")], "foo" => [2, 1]
    end

    it 'should combine data sources' do
      ds = Ahoy::DataSource.new
      ds.add 'foo', Ahoy::Event.where(name: 'foo').group_by_day(:time).count
      ds.add 'bar', Ahoy::Event.where(name: 'bar').group_by_day(:time).count
      expect(ds.build).to eq :x => [time_1.strftime("%Y-%m-%d"), time_2.strftime("%Y-%m-%d"), time_3.strftime("%Y-%m-%d")], "foo" => [2, 1, 0], "bar" => [1, 0, 2]
    end
  end
end
