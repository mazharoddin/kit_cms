require 'test_helper'

class Admin::FormFieldGroupsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::FormFieldGroup.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::FormFieldGroup.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::FormFieldGroup.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_form_field_group_url(assigns(:form_field_group))
  end

  def test_edit
    get :edit, :id => Admin::FormFieldGroup.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::FormFieldGroup.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::FormFieldGroup.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::FormFieldGroup.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::FormFieldGroup.first
    assert_redirected_to admin_form_field_group_url(assigns(:form_field_group))
  end

  def test_destroy
    form_field_group = Admin::FormFieldGroup.first
    delete :destroy, :id => form_field_group
    assert_redirected_to admin_form_field_groups_url
    assert !Admin::FormFieldGroup.exists?(form_field_group.id)
  end
end
