class SetCookieSession
  
  def initialize(app)
    @app = app
  end
 
  def call(env)
    host = env["HTTP_HOST"].split(':').first
    env["rack.session.options"][:domain] = "." + host
    @app.call(env)
  end
 
end