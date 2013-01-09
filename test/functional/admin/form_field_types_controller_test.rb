require 'test_helper'

class Admin::FormFieldTypesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::FormFieldType.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::FormFieldType.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::FormFieldType.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_form_field_type_url(assigns(:form_field_type))
  end

  def test_edit
    get :edit, :id => Admin::FormFieldType.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::FormFieldType.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::FormFieldType.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::FormFieldType.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::FormFieldType.first
    assert_redirected_to admin_form_field_type_url(assigns(:form_field_type))
  end

  def test_destroy
    form_field_type = Admin::FormFieldType.first
    delete :destroy, :id => form_field_type
    assert_redirected_to admin_form_field_types_url
    assert !Admin::FormFieldType.exists?(form_field_type.id)
  end
end
