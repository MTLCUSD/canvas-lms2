class LoadAccount
  def initialize(app)
    @app = app
  end

  def call(env)
    Account.clear_special_account_cache!
    #domain_root_account = LoadAccount.default_domain_root_account
    domain_root_account = empowered_root_account
    Rails.logger.info "Empowered: LOADING ACCOUNT: #{domain_root_account.id}:#{domain_root_account.name}"
    configure_for_root_account(domain_root_account)

    env['canvas.domain_root_account'] = domain_root_account
    @app.call(env)

  end

  def self.default_domain_root_account; Account.default; end

  def empowered_root_account
    if Empowered_config[:root_account]
      Account.find Empowered_config[:root_account]
    else
      Rails.logger.info "Empowered: NO ACCOUNT FOUND LOADING CANVAS DEFAULT"
      LoadAccount.default_domain_root_account
    end
  end

  protected
  def configure_for_root_account(domain_root_account)
    Attachment.domain_namespace = domain_root_account.file_namespace
  end
end
