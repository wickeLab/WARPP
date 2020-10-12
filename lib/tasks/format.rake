namespace :format do
  desc 'alter wrongly formatted tsv in dir'
  task :correct_tsv, [:dir] => [:environment] do |_t, args|
    Dir["#{args[:dir]}/*"].each do |tsv|
      new_tsv = tsv.rpartition('.')[0] + '_altered.txt'
      CSV.open(new_tsv, 'w', col_sep: "\t") do |new_tsv|
        File.open(tsv).each do |line|
          new_tsv << line.strip.split("\t").map { |element| element.empty? ? nil : element }
        end
      end

      `rm #{tsv}`
      `mv #{new_tsv} #{tsv}`
    end
  end

end
