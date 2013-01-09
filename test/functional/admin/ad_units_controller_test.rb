require 'test_helper'

class Admin::AdUnitsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => AdUnit.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    AdUnit.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    AdUnit.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_ad_unit_url(assigns(:ad_unit))
  end

  def test_edit
    get :edit, :id => AdUnit.first
    assert_template 'edit'
  end

  def test_update_invalid
    AdUnit.any_instance.stubs(:valid?).returns(false)
    put :update, :id => AdUnit.first
    assert_template 'edit'
  end

  def test_update_valid
    AdUnit.any_instance.stubs(:valid?).returns(true)
    put :update, :id => AdUnit.first
    assert_redirected_to admin_ad_unit_url(assigns(:ad_unit))
  end

  def test_destroy
    ad_unit = AdUnit.first
    delete :destroy, :id => ad_unit
    assert_redirected_to admin_ad_units_url
    assert !AdUnit.exists?(ad_unit.id)
  end
end
