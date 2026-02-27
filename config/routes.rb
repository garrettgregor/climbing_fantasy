require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  devise_for :admin_users
  ActiveAdmin.routes(self)

  authenticate :admin_user, ->(u) { u.super_admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  namespace :api do
    namespace :v1 do
      resources :seasons, only: [ :index, :show ]
      resources :events, only: [ :index, :show ]
      resources :categories, only: [ :show ]
      resources :rounds, only: [ :show ]
      resources :athletes, only: [ :index, :show ]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end

# == Route Map
#
# Routes for application:
#                            Prefix Verb   URI Pattern                                                                                       Controller#Action
#                          rswag_ui        /api-docs                                                                                         Rswag::Ui::Engine
#                         rswag_api        /api-docs                                                                                         Rswag::Api::Engine
#            new_admin_user_session GET    /admin_users/sign_in(.:format)                                                                    devise/sessions#new
#                admin_user_session POST   /admin_users/sign_in(.:format)                                                                    devise/sessions#create
#        destroy_admin_user_session DELETE /admin_users/sign_out(.:format)                                                                   devise/sessions#destroy
#           new_admin_user_password GET    /admin_users/password/new(.:format)                                                               devise/passwords#new
#          edit_admin_user_password GET    /admin_users/password/edit(.:format)                                                              devise/passwords#edit
#               admin_user_password PATCH  /admin_users/password(.:format)                                                                   devise/passwords#update
#                                   PUT    /admin_users/password(.:format)                                                                   devise/passwords#update
#                                   POST   /admin_users/password(.:format)                                                                   devise/passwords#create
#    cancel_admin_user_registration GET    /admin_users/cancel(.:format)                                                                     devise/registrations#cancel
#       new_admin_user_registration GET    /admin_users/sign_up(.:format)                                                                    devise/registrations#new
#      edit_admin_user_registration GET    /admin_users/edit(.:format)                                                                       devise/registrations#edit
#           admin_user_registration PATCH  /admin_users(.:format)                                                                            devise/registrations#update
#                                   PUT    /admin_users(.:format)                                                                            devise/registrations#update
#                                   DELETE /admin_users(.:format)                                                                            devise/registrations#destroy
#                                   POST   /admin_users(.:format)                                                                            devise/registrations#create
#                        admin_root GET    /admin(.:format)                                                                                  admin/dashboard#index
#    batch_action_admin_admin_users POST   /admin/admin_users/batch_action(.:format)                                                         admin/admin_users#batch_action
#                 admin_admin_users GET    /admin/admin_users(.:format)                                                                      admin/admin_users#index
#                                   POST   /admin/admin_users(.:format)                                                                      admin/admin_users#create
#              new_admin_admin_user GET    /admin/admin_users/new(.:format)                                                                  admin/admin_users#new
#             edit_admin_admin_user GET    /admin/admin_users/:id/edit(.:format)                                                             admin/admin_users#edit
#                  admin_admin_user GET    /admin/admin_users/:id(.:format)                                                                  admin/admin_users#show
#                                   PATCH  /admin/admin_users/:id(.:format)                                                                  admin/admin_users#update
#                                   PUT    /admin/admin_users/:id(.:format)                                                                  admin/admin_users#update
#                                   DELETE /admin/admin_users/:id(.:format)                                                                  admin/admin_users#destroy
#       batch_action_admin_athletes POST   /admin/athletes/batch_action(.:format)                                                            admin/athletes#batch_action
#                    admin_athletes GET    /admin/athletes(.:format)                                                                         admin/athletes#index
#                                   POST   /admin/athletes(.:format)                                                                         admin/athletes#create
#                 new_admin_athlete GET    /admin/athletes/new(.:format)                                                                     admin/athletes#new
#                edit_admin_athlete GET    /admin/athletes/:id/edit(.:format)                                                                admin/athletes#edit
#                     admin_athlete GET    /admin/athletes/:id(.:format)                                                                     admin/athletes#show
#                                   PATCH  /admin/athletes/:id(.:format)                                                                     admin/athletes#update
#                                   PUT    /admin/athletes/:id(.:format)                                                                     admin/athletes#update
#                                   DELETE /admin/athletes/:id(.:format)                                                                     admin/athletes#destroy
#     batch_action_admin_categories POST   /admin/categories/batch_action(.:format)                                                          admin/categories#batch_action
#                  admin_categories GET    /admin/categories(.:format)                                                                       admin/categories#index
#                                   POST   /admin/categories(.:format)                                                                       admin/categories#create
#                new_admin_category GET    /admin/categories/new(.:format)                                                                   admin/categories#new
#               edit_admin_category GET    /admin/categories/:id/edit(.:format)                                                              admin/categories#edit
#                    admin_category GET    /admin/categories/:id(.:format)                                                                   admin/categories#show
#                                   PATCH  /admin/categories/:id(.:format)                                                                   admin/categories#update
#                                   PUT    /admin/categories/:id(.:format)                                                                   admin/categories#update
#                                   DELETE /admin/categories/:id(.:format)                                                                   admin/categories#destroy
#   batch_action_admin_competitions POST   /admin/competitions/batch_action(.:format)                                                        admin/competitions#batch_action
#                admin_competitions GET    /admin/competitions(.:format)                                                                     admin/competitions#index
#                                   POST   /admin/competitions(.:format)                                                                     admin/competitions#create
#             new_admin_competition GET    /admin/competitions/new(.:format)                                                                 admin/competitions#new
#            edit_admin_competition GET    /admin/competitions/:id/edit(.:format)                                                            admin/competitions#edit
#                 admin_competition GET    /admin/competitions/:id(.:format)                                                                 admin/competitions#show
#                                   PATCH  /admin/competitions/:id(.:format)                                                                 admin/competitions#update
#                                   PUT    /admin/competitions/:id(.:format)                                                                 admin/competitions#update
#                                   DELETE /admin/competitions/:id(.:format)                                                                 admin/competitions#destroy
#                   admin_dashboard GET    /admin/dashboard(.:format)                                                                        admin/dashboard#index
#  batch_action_admin_round_results POST   /admin/round_results/batch_action(.:format)                                                       admin/round_results#batch_action
#               admin_round_results GET    /admin/round_results(.:format)                                                                    admin/round_results#index
#                                   POST   /admin/round_results(.:format)                                                                    admin/round_results#create
#            new_admin_round_result GET    /admin/round_results/new(.:format)                                                                admin/round_results#new
#           edit_admin_round_result GET    /admin/round_results/:id/edit(.:format)                                                           admin/round_results#edit
#                admin_round_result GET    /admin/round_results/:id(.:format)                                                                admin/round_results#show
#                                   PATCH  /admin/round_results/:id(.:format)                                                                admin/round_results#update
#                                   PUT    /admin/round_results/:id(.:format)                                                                admin/round_results#update
#                                   DELETE /admin/round_results/:id(.:format)                                                                admin/round_results#destroy
#         batch_action_admin_rounds POST   /admin/rounds/batch_action(.:format)                                                              admin/rounds#batch_action
#                      admin_rounds GET    /admin/rounds(.:format)                                                                           admin/rounds#index
#                                   POST   /admin/rounds(.:format)                                                                           admin/rounds#create
#                   new_admin_round GET    /admin/rounds/new(.:format)                                                                       admin/rounds#new
#                  edit_admin_round GET    /admin/rounds/:id/edit(.:format)                                                                  admin/rounds#edit
#                       admin_round GET    /admin/rounds/:id(.:format)                                                                       admin/rounds#show
#                                   PATCH  /admin/rounds/:id(.:format)                                                                       admin/rounds#update
#                                   PUT    /admin/rounds/:id(.:format)                                                                       admin/rounds#update
#                                   DELETE /admin/rounds/:id(.:format)                                                                       admin/rounds#destroy
#        batch_action_admin_seasons POST   /admin/seasons/batch_action(.:format)                                                             admin/seasons#batch_action
#                     admin_seasons GET    /admin/seasons(.:format)                                                                          admin/seasons#index
#                                   POST   /admin/seasons(.:format)                                                                          admin/seasons#create
#                  new_admin_season GET    /admin/seasons/new(.:format)                                                                      admin/seasons#new
#                 edit_admin_season GET    /admin/seasons/:id/edit(.:format)                                                                 admin/seasons#edit
#                      admin_season GET    /admin/seasons/:id(.:format)                                                                      admin/seasons#show
#                                   PATCH  /admin/seasons/:id(.:format)                                                                      admin/seasons#update
#                                   PUT    /admin/seasons/:id(.:format)                                                                      admin/seasons#update
#                                   DELETE /admin/seasons/:id(.:format)                                                                      admin/seasons#destroy
#                    admin_comments GET    /admin/comments(.:format)                                                                         admin/comments#index
#                                   POST   /admin/comments(.:format)                                                                         admin/comments#create
#                     admin_comment GET    /admin/comments/:id(.:format)                                                                     admin/comments#show
#                                   DELETE /admin/comments/:id(.:format)                                                                     admin/comments#destroy
#                       sidekiq_web        /sidekiq                                                                                          Sidekiq::Web
#                    api_v1_seasons GET    /api/v1/seasons(.:format)                                                                         api/v1/seasons#index
#                     api_v1_season GET    /api/v1/seasons/:id(.:format)                                                                     api/v1/seasons#show
#               api_v1_competitions GET    /api/v1/competitions(.:format)                                                                    api/v1/competitions#index
#                api_v1_competition GET    /api/v1/competitions/:id(.:format)                                                                api/v1/competitions#show
#                   api_v1_category GET    /api/v1/categories/:id(.:format)                                                                  api/v1/categories#show
#                      api_v1_round GET    /api/v1/rounds/:id(.:format)                                                                      api/v1/rounds#show
#                   api_v1_athletes GET    /api/v1/athletes(.:format)                                                                        api/v1/athletes#index
#                    api_v1_athlete GET    /api/v1/athletes/:id(.:format)                                                                    api/v1/athletes#show
#                rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#  turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#  turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
# turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#                rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#          rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                   GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#         rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#   rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                   GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#         update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#              rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for Rswag::Ui::Engine:
# No routes defined.
#
# Routes for Rswag::Api::Engine:
# No routes defined.
