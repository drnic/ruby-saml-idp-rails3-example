# Example SAML Identity Provider in Rails 3

This is an example Rails 3 app behaving as a trivial SAML IdP (Identity Provider) using https://github.com/lawrencepit/ruby-saml-idp It exists mostly to allow you to test your SAML Service Provider implementation.

[SAML](http://en.wikipedia.org/wiki/Security_Assertion_Markup_Language) (Security Assertion Markup Language) is an XML-based open standard for exchanging authentication and authorization data between security domains, that is, between an identity provider (a producer of assertions) and a service provider (a consumer of assertions).

A SAML IdP offers Single Sign On to one or more web applications (SAML Service Providers). Based on its implementation it may actually be a proxy to an LDAP or ActiveDirectory server within your organization. This example IdP does not do that. It exists mostly to allow you to test your SAML Service Provider implementation.

In production, you would allow your corporate customers to connect their own SAML IdP to your web application (a SAML Service Provider). Alternately, they could outsource the hosting of a SAML IdP to a company like [onelogin](http://onelogin.com/) or a self-hosted solution like [PingFederate](https://www.pingidentity.com/products/pingfederate/).

## Usage

A SAML IdP is a running web application that has two-way communication, and browser redirection, with one or more SAML Service Providers (web applications that you actually want to use).

Since this codebase exists primarily to allow you to test your own SAML implementation, you could throw it up on the free Heroku hosting service:

```
cd /tmp
git clone git://github.com/drnic/ruby-saml-idp-rails3-example.git
cd ruby-saml-idp-rails3-example
bundle
heroku create
git push heroku master
heroku run rake db:migrate
heroku apps:info
```

The "Web URL" value will be used when registering this example IdP with your SAML SP.

## Testing IdP with example SP

If you want to see the example IdP work with an example SP, then [you are in luck!](https://github.com/calh/ruby-saml-rails3-example).

```
cd /tmp
git clone git://github.com/drnic/ruby-saml-rails3-example.git
cd ruby-saml-rails3-example
bundle
heroku create
git push heroku master
heroku run rake db:migrate
# when its finished...
heroku apps:open
```

This automatically redirects to /saml endpoint, which shows "No Settings" header.

Click on "Admin section" to create your first IdP backend (NOTE: the example SP app only supports on IdP backend currently).

For this example IdP, which doesn't have a metadata endpoint, the only fields to fill in are the last two:

* IdP Cert Fingerprint: 9E:65:2E:03:06:8D:80:F2:86:C7:6C:77:A1:D9:14:97:0A:4D:F4:4D (provided by ruby-saml-idp for the example)
* IdP SSO Target URL: the "Web URL" from above with suffix "/saml/auth"

For example:

![Example IdP configuration in SP administration](https://img.skitch.com/20120703-nspp9atxqqw3pjqnfhh35cdf88.png "Example IdP configuration in SP administration")

Click "Create account" to save the IdP backend.

Your administration of an IdP backend is complete. You can now pretend to be a real user. Go to the home page of the SP application:

```
heroku apps:open
```

You'll see "Not logged in." Click on "Log in". Notice that the browser URL changes from your SP app to your IdP application.

Enter any email/password (values are ignored, see "Example authentication controller" section below). Click "Sign in".

You are now returned to the SP application and will see something like this:

![Example SP after authentication at IdP](https://img.skitch.com/20120703-gtpr5ftuxpw3nbwf8998t94u2b.png "Example SP after authentication at IdP")

Congratulations, as a user of the SP example application you have authenticated in via the IdP application.

## Example authentication controller

The authentication controller accepts any email/password and always returns "you@example.com".

``` ruby
class SamlIdpController < SamlIdp::IdpController

  def idp_authenticate(email, password)
    true
  end

  def idp_make_saml_response(user)
    encode_SAMLResponse("you@example.com")
  end

end
```

Another almost-as-trivial controller is in [ruby-saml-idp's specs](https://github.com/lawrencepit/ruby-saml-idp/blob/master/spec/rails_app/app/controllers/saml_idp_controller.rb):

``` ruby
class SamlIdpController < SamlIdp::IdpController

  def idp_authenticate(email, password)
    { :email => email }
  end

  def idp_make_saml_response(user)
    encode_SAMLResponse(user[:email])
  end

end
```

If you were actually going to use this code base as a real single-sign on (SSO) server with accounts and users, then you might do something like following (which comes from the README of ruby-saml-idp):

``` ruby
class SamlIdpController < SamlIdp::IdpController
  before_filter :find_account
  # layout 'saml_idp'

  def idp_authenticate(email, password)
    user = @account.users.where(:email => params[:email]).first
    user && user.valid_password?(params[:password]) ? user : nil
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
```
