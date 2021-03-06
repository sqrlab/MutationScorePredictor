@experiment_runs = 10
@experiment_resources_dir = "#{Dir.pwd}/lib/experiment_resources"

desc "Perform cross validation using all feature sets on the 'all' project"
task :cross_validation_all_features_experiment do

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/cross_validation").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/cross_validation",entry) and !(entry =='.' || entry == '..') }

  features.each do |feature|

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    projects.each do |project|

      # Ignore all other projects except the 'all' project
      next if project != "all"
      puts "[LOG] Feature Set: #{feature}  Project: #{project}"

      file = "#{@experiment_resources_dir}/cross_validation/#{project}/cross_validation_#{feature.chomp(".rb")}.txt"

      FileUtils.cp("#{@experiment_resources_dir}/cross_validation/#{project}/configuration.rb", "#{@home}/lib/rake_tasks/configuration.rb")
      if File.exist?(file)
        FileUtils.rm(file)
      end
      @experiment_runs.times do |i|
        `time rake cross_validation >> #{file}`
      end
    end
  end
end

desc "Perform cross validation using the three combined feature sets on all individual project"
task :cross_validation_all_projects_experiment do

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/cross_validation").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/cross_validation",entry) and !(entry =='.' || entry == '..') }

  features.each do |feature|

    # Ignore all features that are not the combine sets
    next if !feature.include?("combine")

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    projects.each do |project|

      # Ignore the 'all' project
      next if project == "all"
      puts "[LOG] Feature Set: #{feature}  Project: #{project}"

      file = "#{@experiment_resources_dir}/cross_validation/#{project}/cross_validation_#{feature.chomp(".rb")}.txt"

      FileUtils.cp("#{@experiment_resources_dir}/cross_validation/#{project}/configuration.rb", "#{@home}/lib/rake_tasks/configuration.rb")
      if File.exist?(file)
        FileUtils.rm(file)
      end
      @experiment_runs.times do |i|
        `time rake cross_validation >> #{file}`
      end
    end
  end
end

desc "Perform training/prediction using the three combined feature sets on all individual projects and subsets of all(excluding one) vs. one"
task :train_predict_all_projects_experiment do

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/prediction").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/prediction",entry) and !(entry =='.' || entry == '..') }

  features.each do |feature|

    # Ignore all features that are not the combine sets
    next if !feature.include?("combine")

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    projects.each do |project|

      # Ignore the 'all' project
      next if project == "all"
      puts "[LOG] Feature Set: #{feature}  Project: #{project}"

      file = "#{@experiment_resources_dir}/prediction/#{project}/prediction_#{feature.chomp(".rb")}.txt"

      FileUtils.cp("#{@experiment_resources_dir}/prediction/#{project}/configuration.rb", "#{@home}/lib/rake_tasks/configuration.rb")
      if File.exist?(file)
        FileUtils.rm(file)
      end
      @experiment_runs.times do |i|
        `time rake train_predict >> #{file}`
      end
    end
  end
end

desc "Perform training/prediction using the three combined feature sets on all individual projects and subsets of all(excluding one) vs. one using set parameters"
task :train_predict_all_projects_with_parameters_experiment, :type, :cost, :gamma, :needs => [:sqlite3] do |t, args|

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/prediction").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/prediction",entry) and !(entry =='.' || entry == '..') }

  features.each do |feature|

    # Ignore all features that are not the combine sets
    next if !feature.include?("combine")

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    projects.each do |project|

      # Ignore the 'all' project
      next if project == "all"
      puts "[LOG] Feature Set: #{feature}  Project: #{project}"

      file = "#{@experiment_resources_dir}/prediction/#{project}/prediction_#{args[:type]}_parameters_#{feature.chomp(".rb")}.txt"

      FileUtils.cp("#{@experiment_resources_dir}/prediction/#{project}/configuration.rb", "#{@home}/lib/rake_tasks/configuration.rb")
      if File.exist?(file)
        FileUtils.rm(file)
      end
      @experiment_runs.times do |i|
        `time rake train_predict_type_with_cost_gamma[\"#{args[:type]}\",#{args[:cost]},#{args[:gamma]}] >> #{file}`
      end
    end
  end
end

desc "Perform training/prediction of each project on itself using the specified parameters while incrementally increasing the divisor for unknowns"
task :train_predict_each_project_incremental_divisor, :type, :feature, :cost, :gamma, :needs => [:sqlite3] do |t, args|

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/prediction").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/prediction",entry) and !(entry =='.' || entry == '..') }
  original_divisor = File.open("#{@home}/lib/rake_tasks/configuration.rb").read.scan(/@@divisor = (\d+)/)[0][0]

  features.each do |feature|

    # Ignore all features that does not match the selected
    next if !feature.include?("#{args[:feature]}.rb")

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    projects.each do |project|

      # Ignore the but the individual projects
      next if project.include?("all")
      puts "[LOG] Feature Set: #{feature}  Project: #{project}"

      FileUtils.cp("#{@experiment_resources_dir}/prediction/#{project}/configuration.rb", "#{@home}/lib/rake_tasks/configuration.rb")

      @divisor_range.each do |divisor|

        changes = File.open("#{@home}/lib/rake_tasks/configuration.rb").read.sub(/@@divisor = (\d+)/, "@@divisor = #{divisor}")
        File.open("#{@home}/lib/rake_tasks/configuration.rb", 'w') {|f| f.write(changes) }

        file = "#{@experiment_resources_dir}/prediction/#{project}/prediction_#{args[:type]}_divisor_#{divisor}_#{feature.chomp(".rb")}.txt"

        if File.exist?(file)
          FileUtils.rm(file)
        end

        @experiment_runs.times do |i|
          `time rake train_predict_type_with_cost_gamma[\"#{args[:type]}\",#{args[:cost]},#{args[:gamma]}] >> #{file}`
        end
      end
    end
  end

  # Revert the divisor back to original
  changes = File.open("#{@home}/lib/rake_tasks/configuration.rb").read.sub(/@@divisor = (\d+)/, "@@divisor = #{original_divisor}")
  File.open("#{@home}/lib/rake_tasks/configuration.rb", 'w') {|f| f.write(changes) }
end

desc "Perform grid search on the prediction set using the three combined feature sets on all individual projects and subsets of all(excluding one) vs. one"
task :grid_search_experiment do

  FileUtils.mkdir("#{@experiment_resources_dir}/grid_search/") if !File.directory?("#{@experiment_resources_dir}/grid_search/")
  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }

  features.each do |feature|

    # Ignore all features that are not the combine sets
    next if !feature.include?("combine")
    puts "[LOG] Feature Set: #{feature}"

    FileUtils.cp("#{@experiment_resources_dir}/feature_sets/#{feature}", "#{@home}/lib/feature_sets.rb")

    `time rake grid_search_all_vs_one["class"] > #{@experiment_resources_dir}/grid_search/all_vs_one_class_#{feature.chomp(".rb")}.txt`
    `time rake grid_search_all_vs_one["method"] > #{@experiment_resources_dir}/grid_search/all_vs_one_method_#{feature.chomp(".rb")}.txt`

    `time rake grid_search_all_self["class"] > #{@experiment_resources_dir}/grid_search/all_self_class_#{feature.chomp(".rb")}.txt`
    `time rake grid_search_all_self["method"] > #{@experiment_resources_dir}/grid_search/all_self_method_#{feature.chomp(".rb")}.txt`

    `time rake grid_search_each_self["class"] > #{@experiment_resources_dir}/grid_search/each_individual_class_#{feature.chomp(".rb")}.txt`
    `time rake grid_search_each_self["method"] > #{@experiment_resources_dir}/grid_search/each_individual_method_#{feature.chomp(".rb")}.txt`
  end
end

desc "Analyze the class/method mean and standard deviation of the experiment results"
task :analyze_experiment_results do

  features = Dir.entries("#{@experiment_resources_dir}/feature_sets").select {|entry| !File.directory? File.join("#{@experiment_resources_dir}/feature_sets",entry) and !(entry =='.' || entry == '..') }
  projects = Dir.entries("#{@experiment_resources_dir}/cross_validation").select {|entry| File.directory? File.join("#{@experiment_resources_dir}/cross_validation",entry) and !(entry =='.' || entry == '..') }

  projects.each do |project|
    features.each do |feature|
      file = "#{@experiment_resources_dir}/cross_validation/#{project}/cross_validation_#{feature.chomp(".rb")}.txt"
      if File.exist?(file)
        puts file
        print_mean_sd_accuracy("class", file)
        print_mean_sd_accuracy("method", file)
        puts ""
      end
    end
  end
end

def print_mean_sd_accuracy(type, file)
  total = []
  results = File.open(file, "r").read.scan(/#{type.capitalize} Accuracy = (\d*.\d*)/)
  results.each do |result|
    total << result[0].to_f
  end
  total = total.to_scale
  puts "#{type.capitalize} Mean = #{total.mean}"
  puts "#{type.capitalize} Standard Deviation = #{total.sd}"
end
