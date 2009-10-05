ActionController::Routing::Routes.draw do |map|
  map.resources :partners, :member => {
    :email => :get,    
    :picture => :get,
    :picture_save => :post
  }
  map.resources :users, :has_one => [:password, :profile], :collection => {:endorsements => :get, :order => :post}, :member => {
    :suspend => :put,
    :unsuspend => :put,
    :activities => :get,
    :comments => :get,
    :points => :get,
    :discussions => :get,
    :issues => :get,
    :capital => :get,
    :impersonate => :put,
    :followers => :get,
    :documents => :get,
    :stratml => :get,
    :ignorers => :get,
    :following => :get,
    :ignoring => :get,
    :follow => :post,
    :unfollow => :post,
    :make_admin => :put,
    :ads => :get,
    :priorities => :get,
    :signups => :get,
    :legislators => :get,
    :legislators_save => :post,
    :endorse => :post,
    :reset_password => :get,
    :resend_activation => :get } do |users|
     users.resources :messages
     users.resources :followings, :collection => { :multiple => :put }
     users.resources :contacts, :controller => :user_contacts, :as => "contacts", :collection => {
       :multiple => :put, 
       :following => :get,
       :allies => :get,
       :members => :get,
       :not_invited => :get,
       :invited => :get
    }
  end
  
  map.resources :settings, :collection => {
    :signups => :get,    
    :picture => :get,
    :picture_save => :post,
    :legislators => :get,
    :legislators_save => :post,
    :branch_change => :get,
    :delete => :get 
  }
  
  map.resources :priorities, 
    :member => { 
      :flag_inappropriate => :put, 
      :bury => :put, 
      :compromised => :put, 
      :successful => :put, 
      :failed => :put, 
      :intheworks => :put, 
      :endorse => :post, 
      :endorsed => :get, 
      :opposed => :get,
      :activities => :get, 
      :endorsers => :get, 
      :opposers => :get, 
      :discussions => :get, 
      :create_short_url => :put,
      :tag => :post, 
      :tag_save => :put, 
      :points => :get, 
      :opposer_points => :get, :endorser_points => :get, :neutral_points => :get, :everyone_points => :get, 
      :opposer_documents => :get, :endorser_documents => :get, :neutral_documents => :get, :everyone_documents => :get,      
      :comments => :get, 
      :documents => :get },
    :collection => { 
      :yours => :get, 
      :yours_finished => :get, 
      :yours_top => :get,
      :yours_ads => :get,
      :yours_lowest => :get,      
      :yours_created => :get,
      :network => :get, 
      :consider => :get, 
      :obama => :get, :not_obama => :get, :obama_opposed => :get,      
      :finished => :get, 
      :ads => :get,
      :top => :get, 
      :rising => :get, 
      :falling => :get, 
      :controversial => :get, 
      :random => :get, 
      :newest => :get, 
      :untagged => :get } do |priorities|
      priorities.resources :changes, :member => { :start => :put, :stop => :put, :approve => :put, :flip => :put, :activities => :get } do |changes|
        changes.resources :votes
      end
      priorities.resources :points
      priorities.resources :documents
      priorities.resources :ads, :collection => {:preview => :post}, :member => {:skip => :post}
    end
  map.resources :activities, :member => { :undelete => :put, :unhide => :get } do |activities|
    activities.resources :followings, :controller => :following_discussions, :as => "followings"
    activities.resources :comments, 
      :collection => { :more => :get }, 
      :member => { :unhide => :get, :flag => :get, :not_abusive => :post, :abusive => :post }
  end 
  map.resources :points, 
    :member => { :activity => :get, 
        :discussions => :get, 
        :quality => :post, 
        :unquality => :post, 
        :unhide => :get },
    :collection => { :newest => :get, :revised => :get, :your_priorities => :get } do |points|
    points.resources :revisions, :member => {:clean => :get}
  end
  map.resources :documents, 
    :member => { :activity => :get, 
      :discussions => :get, :quality => :post, :unquality => :post, :unhide => :get },
    :collection => { :newest => :get, :revised => :get, :your_priorities => :get } do |documents|
    documents.resources :revisions, :controller => :document_revisions, :as => "revisions", 
      :member => {:clean => :get}
  end
  map.resources :legislators, :member => { :priorities => :get } do |legislators|
    legislators.resources :constituents, :collection => { :priorities => :get }
  end
  map.resources :blurbs, :collection => {:preview => :put}
  map.resources :email_templates, :collection => {:preview => :put}  
  map.resources :color_schemes, :collection => {:preview => :put}  
  map.resources :governments, :member => {:apis => :get}
  map.resources :widgets, :collection => {:priorities => :get, :discussions => :get, :points => :get, :preview_iframe => :get, :preview => :post}
  map.resources :bulletins, :member => {:add_inline => :post}
  map.resources :branches, :member => {:default => :post} do |branches|
    branches.resources :priorities, :controller => :branch_priorities, :as => "priorities", 
    :collection => { :top => :get, :rising => :get, :falling => :get, :controversial => :get, :random => :get, :newest => :get, :finished => :get}
    branches.resources :users, :controller => :branch_users, :as => "users",
    :collection => { :talkative => :get, :twitterers => :get, :newest => :get, :ambassadors => :get}
  end
  map.resources :searches, :collection => {:points => :get, :documents => :get}
  map.resources :signups, :endorsements, :passwords, :unsubscribes, :notifications, :pages, :about, :tags
  map.resource :session
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "priorities"

  # restful_authentication routes
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy' 
  map.unsubscribe '/unsubscribe', :controller => 'unsubscribes', :action => 'new'   

  # non restful routes
  map.connect '/yours', :controller => 'priorities', :action => 'yours'
  map.connect '/hot', :controller => 'priorities', :action => 'hot'
  map.connect '/cold', :controller => 'priorities', :action => 'cold'
  map.connect '/new', :controller => 'priorities', :action => 'new'        
  map.connect '/controversial', :controller => 'priorities', :action => 'controversial'
   
  map.connect '/vote/:action/:code', :controller => "vote"
  map.connect '/splash', :controller => 'splash', :action => 'index'
  map.connect '/issues', :controller => "issues"
  map.connect '/issues.:format', :controller => "issues"
  map.connect '/issues/:slug', :controller => "issues", :action => "show"
  map.connect '/issues/:slug.:format', :controller => "issues", :action => "show"  
  map.connect '/issues/:slug/:action', :controller => "issues"
  map.connect '/issues/:slug/:action.:format', :controller => "issues"  

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect '/pictures/:short_name/:action/:id', :controller => "pictures"
  map.connect ':controller'
  map.connect ':controller/:action'  
  map.connect ':controller/:action.:format' # this one is not needed for rails 2.3.2, and must be removed
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
