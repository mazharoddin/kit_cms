require 'test_helper'

class Admin::FormsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::Form.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::Form.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::Form.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_form_url(assigns(:form))
  end

  def test_edit
    get :edit, :id => Admin::Form.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::Form.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::Form.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::Form.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::Form.first
    assert_redirected_to admin_form_url(assigns(:form))
  end

  def test_destroy
    form = Admin::Form.first
    delete :destroy, :id => form
    assert_redirected_to admin_forms_url
    assert !Admin::Form.exists?(form.id)
  end
end
