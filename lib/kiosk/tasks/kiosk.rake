namespace :kiosk do
  desc "Helper task for content indexing."
  task :index, [:index_name] => [:environment] do |task,arguments|
    Kiosk.origin.indexer.index(arguments.index_name)
  end
end
