require 'test_helper'

class Admin::ViewsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => View.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    View.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    View.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_view_url(assigns(:view))
  end

  def test_edit
    get :edit, :id => View.first
    assert_template 'edit'
  end

  def test_update_invalid
    View.any_instance.stubs(:valid?).returns(false)
    put :update, :id => View.first
    assert_template 'edit'
  end

  def test_update_valid
    View.any_instance.stubs(:valid?).returns(true)
    put :update, :id => View.first
    assert_redirected_to admin_view_url(assigns(:view))
  end

  def test_destroy
    view = View.first
    delete :destroy, :id => view
    assert_redirected_to admin_views_url
    assert !View.exists?(view.id)
  end
end
