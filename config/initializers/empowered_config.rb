Empowered_config =    YAML.load_file("#{RAILS_ROOT}/config/empowered.yml")[RAILS_ENV].symbolize_keys rescue nil
Empowered_s3_config = YAML.load_file("#{RAILS_ROOT}/config/amazon_s3.yml")[RAILS_ENV].symbolize_keys rescue nil

