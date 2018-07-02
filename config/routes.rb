require 'sidekiq/web'

Rails.application.routes.draw do

  get 'venues/:id/view' => 'venues#view', as: :venue_view
  post 'venues/:id/available' => 'venues#available', as: :venue_available

  get 'venues/:id/court_price_at' => 'venues#court_price_at',
      as: :court_price_at
  get 'venues/:id/manage_venue' => 'venues#courts_and_prices',
      as: :courts_and_prices

  post '/search' => 'pages#search', as: :search
  get '/search' => 'pages#search', as: :searchget

  get 'venues/:id/cancelled_reservations' => 'venues#cancelled_reservations', as: :venue_cancelled_reservations
  get 'venues/:id/memberships' => 'venues#memberships', as: :memberships
  get 'users/:id/invoices' => 'users#invoices', as: :user_invoices

  devise_scope :admin do
    root to: "devise/sessions#new"
  end

  # no devise_scope for :coaches. Magic is happening due to Coach#devise_scope method

  get '/search' => 'pages#search'
  post '/search' => 'pages#search'

  namespace :api do
    resources :devices, only: [:create] do
      collection do
        delete 'destroy'
      end
    end
    post 'locale' => 'base#locale'
    post 'authenticate' => 'auth#authenticate'
    post 'auth/renew_token' => 'auth#renew_token'
    get "sort_by_sport" => "venues#sort_by_sport"
    resources :cities, only: [:index]
    resources :invoices, only: [:show, :index] do
      post :pay
    end
    resources :users, only: [:create, :update, :destroy] do
      get 'game_pass_check'
      get 'game_passes'
      post :change_location
      collection do
        post :upload_photo
        post :confirm_account_email
        get :email_check
      end
      scope module: :users do
        resources :subscriptions, only: [] do
          collection do
            get :venues
            patch :toggle_email_subscription
          end
        end
        get 'settings/:scope'  => 'settings#index'
        patch 'settings/:scope/:name'  => 'settings#update'
      end
    end
    resources :groups, only: [:index, :show]
    resources :participations, only: [:index, :show] do
      patch :cancel, on: :member
    end
    resources :participation_credits, only: [:index, :show] do
      patch :use, on: :member
    end
    resources :companies, only: [] do
      post 'send_support_email'
      get 'customers'
    end
    get 'search' => 'search#venues'
    get 'search/filter_by_name' => 'search#filter_by_name'
    get 'all_sport_names' => 'venues#all_sport_names'
    resources :cards, only: [:create, :index, :destroy], param: :token
    resources :reservations, only: [:create, :index, :destroy] do
      get :download
      get :resell
      post :payment
    end
    resources :subscriptions, only: [:index]
    resources :courts, only: [] do
      collection do
        get 'types'
        get 'surfaces'
        get 'reservations'
      end
    end
    resources :discounts, only: [:update, :show]
    resources :venues, only: [:show, :index] do
      collection do
        get 'favourites'
      end
      resources :discounts, only: [:create]
      resources :custom_mails, only: [:index]
      resources :reviews, only: [:index, :create, :update, :destroy]
      get 'sports'
      get 'users'
      get 'utilization_rate'
      get 'available_courts'
      get 'courts'
      post 'make_favourite'
      post 'unfavourite'
      get 'group_classifications'
    end
    resources :game_passes, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get :court_sports
        get :court_types
        get :templates
        get :available
      end
    end
    resources :customers, only: [:index, :show, :create, :update, :destroy]
    patch '/user/countries/:country_id' => 'user_countries#update'
    resources :mailchimp_subscribers, only: :create
  end

  post '/connect/managed' => 'stripe#managed', as: 'stripe_managed'

  namespace :admin do
    resource :profile, controller: :profile, only: [:update]
    resource :company, controller: :company, only: [:show, :update] do
      get :is_public
    end

    scope :companies, module: :companies do
      resources :admins, only: [:index, :show, :create, :update, :destroy] do
        get :select_options
        collection do
          patch :permissions
          delete :destroy_many
        end
      end
      resources :activity_logs, only: [:index]
      resources :coaches, only: [:index, :show, :create, :update, :destroy] do
        collection do
          delete :destroy_many
          get :select_options
        end
      end

      resources :coupons, only: [:show], param: :code

      resource :note, only: [:show, :update]
      resources :email_notifications, only: [:index] do
        collection do
          patch :update_many
        end
      end
    end

    resources :users, only: [:index, :show, :update, :create, :destroy] do
      collection do
        get :select_options
      end
      scope module: :users do
        resources :invoices, only: [:index]
      end
    end

    resources :invoices, only: [:index, :show, :create, :update, :destroy] do
      delete :destroy_many, on: :collection
      post :create_drafts, on: :collection
      collection do
        patch :send_all
        patch :unsend_all
        patch :mark_paid
        get :print_all
      end
    end

    resources :reservations, only: [:index] do
      collection do
        get :future_reservations
        get :reservations_between
        delete :destroy_many
      end

      scope module: :reservations do
        resources :logs, only: [:index]
      end
    end

    resources :groups, only: [:index]

    resources :venues, only: [:index, :show, :create, :update, :destroy] do
      member do
        get :select_options_for_court_sports
        get :select_options_for_court_surfaces
        get :closing_hours
        get :weather
      end

      scope module: :venues do
        get 'settings/:scope'  => 'settings#index'

        resources :reservations, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :copy
            patch :toggle_resell_state
            patch :resell_to_user
          end
          collection do
            patch :mark_salary_paid_many
          end

          scope module: :reservations do
            resources :participations, only: [:index, :show, :create, :destroy] do
              collection do
                delete :destroy_many
                patch :mark_paid_many
              end
            end
          end
        end

        resources :courts, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            get :select_options
            get :available_select_options
            get :active # calendar action
            get :calendar_resources # calendar action
            post :prices_at # calendar action, post because may transfer more data than query string can handle
            get :calendar_print # print action for calendar
            get :available_indexes
          end
        end

        resources :holidays, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get :all_for_calendar
            delete :destroy_many
          end
        end

        resources :game_passes, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            get :available_for_select

            scope module: :game_passes do
              resources :templates, only: [:index] do
                collection do
                  get :select_options
                end
              end
            end
          end
        end

        resources :discounts, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            get :select_options
          end
          member do
            delete :remove_from_user
            post :add_to_user
          end
        end

        resources :memberships, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            post :import
            patch :renew_many
          end
        end

        resources :users, only: [] do
          collection do
            post :import
          end
        end

        resources :prices, only: [:index, :show, :create, :update, :destroy]

        resource :dashboard, controller: :dashboard, only: [:show]
        namespace :emails do
          resources :custom_emails, only: [:index, :create]
          resources :lists, only: [:index, :create, :update, :destroy] do
            collection do
              get :select_options
            end

            scope module: :lists do
              resources :users, only: [:index] do
                collection do
                  post :add_many
                  delete :remove_many
                  get :not_listed
                end
              end
            end
          end
        end
        resources :coaches, only: [] do
          scope module: :coaches do
            resources :salary_rates, only: [:index, :show, :create, :update, :destroy] do
              collection do
                delete :destroy_many
              end
            end
            resources :price_rates, only: [:index, :show, :create, :update, :destroy] do
              collection do
                get :unavailable_times
                post :create_many
                delete :destroy_many
              end
            end
            resources :reports, only: [:index] do
              collection do
                get :download
              end
            end
            resources :reservations, only: [:index] do
              collection do
                get :unavailable_slots
              end
            end
          end
          collection do
            get :available_select_options
          end
        end

        resources :groups, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            post :duplicate_many
            get :select_options
          end
          scope module: :groups do
            resources :members, only: [:index, :create, :show, :destroy] do
              collection do
                delete :destroy_many
              end
            end
            resources :subscriptions, only: [:index, :destroy] do
              collection do
                delete :destroy_many
                patch :mark_paid_many
                patch :mark_unpaid_many
              end
            end
            resources :reservations, only: [:index]
            resources :emails, only: [:create]
          end
        end
        resources :group_classifications, only: [:index, :show, :create, :update, :destroy] do
          collection do
            delete :destroy_many
            get :select_options
          end
        end
      end
    end

    resources :group_custom_billers, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get :groups_options
        delete :destroy_many
      end
    end

    resources :reports, only: [:index] do
      collection do
        get :payment_transfers
        get :download_sales_report
        get :download_invoices_report
        get :sport_name_options
      end
    end
  end


  devise_for :admins,
              controllers: { confirmations: 'admin_devise/confirmations' }

  # more devise mappings for the newer admin area
  devise_for :admins, path_prefix: 'auth', as: :new_admin_devise,
    controllers: {
      sessions: 'admin/auth/sessions',
      registrations: 'admin/auth/registrations',
      passwords: 'admin/auth/passwords',
      confirmations: 'admin/auth/confirmations'
    }

  devise_for  :users,
              path: '',
              path_names: { sign_in: 'login',
                            sign_out: 'logout',
                            edit: 'profile',
                            password: 'api/password'},
              controllers: { omniauth_callbacks: 'custom_devise/omniauth_callbacks',
                             registrations: 'custom_devise/registrations',
                             confirmations: 'custom_devise/confirmations',
                             passwords: 'custom_devise/passwords' }

  # TODO: delete this route (and corresponding action) when frontend becomes react-only
  devise_scope :user do
    patch 'users/update_password' => 'custom_devise/registrations#update_password'
  end

  devise_scope :admin do
    patch '/admins/confirmation' => 'admin_devise/confirmations#update'
    authenticate :admin, lambda { |admin| admin.god? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  end

  resources :users, only: [:show] do
    post 'add_card' => 'stripe#add_card', as: :add_card
    post 'card_reminder'
    post 'assign_discount', as: :assign_discount
    get  'recurring_reservations', on: :member
  end

  resources :companies do
    resources :admins, expect: [:new, :show]
    post :remove_user_from_qi
    get :reports
    post :create_report
    get :report
    resources :invoices do
      collection do
        post :create_custom
        post :create_drafts
        post :send_all
        post :unsend_all
        post :mark_paid
        post :destroy_all
        post :create_report
        post :print_all
      end
    end
    get 'revenue' => 'dashboard#revenue', as: :revenue
    get 'resv' => 'dashboard#resv'
    member do
      post 'import_customers'
      get  'customers_csv_template'
    end
  end
  resources :invoices, only: [:show] do
    resources :invoice_components
    resources :gamepass_invoice_components
    resources :custom_invoice_components
  end

  resource :custom_invoice_components, only: [] do
    collection do
      get :vat
    end
  end

  get 'companies/:id/customers' => 'companies#customers', as: :company_customers
  get 'venues/:id/map_users' => 'venues#map_users', as: :map_users

  resources :memberships, only: [:create] do
    collection do
      post :import
      get :csv_template
    end
  end

  resources :holidays, only: [] do
    post :handle_conflicting
  end

  resources :venues do
    resources :game_passes
    resources :prices, except: [:index, :new, :edit] do
      member do
        post :merge_conflicts
      end
    end
    resources :courts
    resources :reservations do
      get 'new_cart', on: :collection
      get  'resell_to_user_form', on: :member
      post 'resell_to_user', on: :member
      put 'make_copy', on: :member
    end
    resources :memberships, except: [:new, :edit, :update]
    post 'memberships/:id' => 'memberships#update'
    get 'holidays'
    resources :holidays, only: [:create, :destroy]
    get 'court_modal/:id' => 'venues#court_modal', as: :court_modal
    get 'price_modal/:id' => 'venues#price_modal', as: :price_modal
    get 'closing_hours'
    get 'booking_ahead_limit'
    get 'active_courts'
    post 'change_listed' => 'venues#change_listed', as: :change_listed
    member do
      get 'reports'
      post 'booking_sales_report'
      get 'available_court_indexes'
    end
    resources :discounts, except: [:new, :create]
    get 'manage_discounts', as: :manage_discounts
    get 'edit_emails'
    post 'update_emails'
    resources :photos, only: [:create, :destroy] do
      post 'make_primary'
    end
    resources :email_lists do
      post 'remove_users'
      post 'add_users'
      get 'off_list_users'
      get 'listed_users'
    end
  end

  post '/custom_mail(.:format)' => 'email_lists#custom_mail'
  get 'reservations/:id/cancel' => 'reservations#refund', as: :reservation_refund
  get 'reservations/:id/cancel_reservation' => 'reservations#cancel', as: :reservation_cancel
  get 'reservations/:id/resell' => 'reservations#resell', as: :reservation_resell
  get 'reservations/:id/show_log' => 'reservations#show_log', as: :reservation_show_log
  get '/privacypolicy', :to => redirect('/privacypolicy.html')
  get '/termsofuse', :to => redirect('/termsofuse.html')
end
