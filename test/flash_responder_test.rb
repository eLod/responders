require File.dirname(__FILE__) + '/test_helper'

class Address
  attr_accessor :errors
  def self.human_name; 'Address'; end
  
  def initialize
    @errors = {}
  end
end

class FlashResponder < ActionController::Responder
  include Responders::FlashResponder
end

class AddressesController < ApplicationController
  before_filter :set_resource
  self.responder = FlashResponder

  def action
    options = params.slice(:flash)
    flash[:success] = "Flash is set" if params[:set_flash]
    respond_with(@resource, options)
  end
  alias :new     :action
  alias :create  :action
  alias :update  :action
  alias :destroy :action

protected

  def interpolation_options
    { :reference => 'Ocean Avenue' }
  end

  def set_resource
    @resource = Address.new
    @resource.errors[:fail] = true if params[:fail]
  end
end

module Admin
  class AddressesController < ::AddressesController
  end
end

class FlashResponderTest < ActionController::TestCase
  tests AddressesController

  def setup
    Responders::FlashResponder.status_keys = [ :success, :failure ]
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_sets_success_flash_message_on_non_get_requests
    post :create
    assert_equal "Resource created with success", flash[:success]
  end

  def test_sets_failure_flash_message_on_not_get_requests
    post :create, :fail => true
    assert_equal "Resource could not be created", flash[:failure]
  end

  def test_does_not_set_flash_message_on_get_requests
    get :new
    assert flash.empty?
  end

  def test_sets_flash_message_for_the_current_controller
    put :update, :fail => true
    assert_equal "Oh no! We could not update your address!", flash[:failure]
  end

  def test_sets_flash_message_with_resource_name
    put :update
    assert_equal "Nice! Address was updated with success!", flash[:success]
  end

  def test_sets_flash_message_with_interpolation_options
    delete :destroy
    assert_equal "Successfully deleted the address at Ocean Avenue", flash[:success]
  end

  def test_does_not_set_flash_if_flash_false_is_given
    post :create, :flash => false
    assert flash.empty?
  end

  def test_does_not_overwrite_the_flash_if_already_set
    post :create, :set_flash => true
    assert_equal "Flash is set", flash[:success]
  end
end

class NamespacedFlashResponderTest < ActionController::TestCase
  tests Admin::AddressesController

  def setup
    Responders::FlashResponder.status_keys = [ :notice, :alert ]
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_sets_the_flash_message_based_on_the_current_controller
    put :update
    assert_equal "Admin updated address with success", flash[:notice]
  end

  def test_sets_the_flash_message_based_on_namespace_actions
    post :create
    assert_equal "Admin created address with success", flash[:notice]
  end

  def test_fallbacks_to_non_namespaced_controller_flash_message
    delete :destroy
    assert_equal "Successfully deleted the chosen address at Ocean Avenue", flash[:notice]
  end
end