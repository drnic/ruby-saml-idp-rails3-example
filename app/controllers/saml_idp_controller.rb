class SamlIdpController < SamlIdp::IdpController
  before_filter :find_account

  def idp_authenticate(email, password)
    # user = @account.users.where(:email => params[:email]).first
    # user && user.valid_password?(params[:password]) ? user : nil
    true
  end

  def idp_make_saml_response(user)
    encode_SAMLResponse(user.email)
  end

  private

    def find_account
      @subdomain = saml_acs_url[/https?:\/\/(.+?)\.example.com/, 1]
      @account = Account.find_by_subdomain(@subdomain)
      render :status => :forbidden unless @account.saml_enabled?
    end

end
