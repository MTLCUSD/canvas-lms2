Empowered_config = YAML.load_file("#{RAILS_ROOT}/config/empowered.yml")[RAILS_ENV].symbolize_keys rescue nil
