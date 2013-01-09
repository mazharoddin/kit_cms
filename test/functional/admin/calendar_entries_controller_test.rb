require 'test_helper'

class Admin::CalendarEntriesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::CalendarEntry.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::CalendarEntry.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::CalendarEntry.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_calendar_entry_url(assigns(:calendar_entry))
  end

  def test_edit
    get :edit, :id => Admin::CalendarEntry.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::CalendarEntry.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::CalendarEntry.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::CalendarEntry.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::CalendarEntry.first
    assert_redirected_to admin_calendar_entry_url(assigns(:calendar_entry))
  end

  def test_destroy
    calendar_entry = Admin::CalendarEntry.first
    delete :destroy, :id => calendar_entry
    assert_redirected_to admin_calendar_entries_url
    assert !Admin::CalendarEntry.exists?(calendar_entry.id)
  end
end
