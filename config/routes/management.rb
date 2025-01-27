namespace :management do
  root to: "dashboard#index"

  resources :document_verifications, only: [:index, :new, :create] do
    post :check, on: :collection
  end

  resources :email_verifications, only: [:new, :create]
  resources :user_invites, only: [:new, :create]

  resources :users, only: [:new, :create] do
    collection do
      delete :logout
      delete :erase
    end
  end

  resource :account, controller: "account", only: [:show]
  resource :session, only: [:create, :destroy]
  get 'sign_in', to: 'sessions#create', as: :sign_in

  resources :proposals, only: [:index, :new, :create, :show] do
    post :vote, on: :member
    get :print, on: :collection
    post :approve_threshold, on: :member
    post :not_approve, on: :member
    post :approve, on: :member
    post :pending, on: :member
    post :archived, on: :member
  end

  resources :spending_proposals, only: [:index, :new, :create, :show] do
    post :vote, on: :member
    get :print, on: :collection
  end

  resources :budgets, only: :index do
    collection do
      get :create_investments
      get :support_investments
      get :print_investments
    end

    resources :investments, only: [:index, :new, :create, :show, :destroy], controller: 'budgets/investments' do
      post :vote, on: :member
      get :print, on: :collection
    end
  end
end
