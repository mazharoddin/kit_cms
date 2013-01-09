require 'test_helper'

class Admin::CalendarsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::Calendar.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::Calendar.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::Calendar.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_calendar_url(assigns(:calendar))
  end

  def test_edit
    get :edit, :id => Admin::Calendar.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::Calendar.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::Calendar.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::Calendar.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::Calendar.first
    assert_redirected_to admin_calendar_url(assigns(:calendar))
  end

  def test_destroy
    calendar = Admin::Calendar.first
    delete :destroy, :id => calendar
    assert_redirected_to admin_calendars_url
    assert !Admin::Calendar.exists?(calendar.id)
  end
end
