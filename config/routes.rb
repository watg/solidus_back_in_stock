# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :back_in_stock_notifications
  end

  resources :back_in_stock_notifications, only: [:new, :create, :update, :show]
end
