
namespace :interlock do
  desc "Watch the Rails log for Interlock-specific messages"
  task :tail do
    Dir.chdir Rails.root do
      exec("tail -f log/#{Rails.env}.log | grep interlock")
    end
  end
end
