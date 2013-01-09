Dummy::Application.routes.draw do
  Mercury::Engine.routes
  devise_for :users
end
