namespace :homepage do

  desc "Initialize feeds available in homepage"
  task create_feeds: :environment do
    %w(proposals debates processes).each do |kind|
      Widget::Feed.create(kind: kind)

      Setting['feature.homepage.widgets.feeds.proposals'] = false
      Setting['feature.homepage.widgets.feeds.debates'] = false
      Setting['feature.homepage.widgets.feeds.processes'] = false
    end
  end

end
