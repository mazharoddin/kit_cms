require 'test_helper'

class Admin::AdZonesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => AdZone.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    AdZone.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    AdZone.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_ad_zone_url(assigns(:ad_zone))
  end

  def test_edit
    get :edit, :id => AdZone.first
    assert_template 'edit'
  end

  def test_update_invalid
    AdZone.any_instance.stubs(:valid?).returns(false)
    put :update, :id => AdZone.first
    assert_template 'edit'
  end

  def test_update_valid
    AdZone.any_instance.stubs(:valid?).returns(true)
    put :update, :id => AdZone.first
    assert_redirected_to admin_ad_zone_url(assigns(:ad_zone))
  end

  def test_destroy
    ad_zone = AdZone.first
    delete :destroy, :id => ad_zone
    assert_redirected_to admin_ad_zones_url
    assert !AdZone.exists?(ad_zone.id)
  end
end
