Rails.application.routes.draw do
  resources :games
  resources :players

  post '/users' => 'players#create'
  post '/login' =>  'players#login'
  get '/notifications' => 'games#notifications'
  post '/games/:id/confirm' => 'games#confirm'
  get '/my_games' => 'games#my_games'
end
