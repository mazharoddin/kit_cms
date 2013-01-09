require 'test_helper'

class Admin::PageTemplatesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => PageTemplate.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    PageTemplate.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    PageTemplate.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_page_template_url(assigns(:page_template))
  end

  def test_edit
    get :edit, :id => PageTemplate.first
    assert_template 'edit'
  end

  def test_update_invalid
    PageTemplate.any_instance.stubs(:valid?).returns(false)
    put :update, :id => PageTemplate.first
    assert_template 'edit'
  end

  def test_update_valid
    PageTemplate.any_instance.stubs(:valid?).returns(true)
    put :update, :id => PageTemplate.first
    assert_redirected_to admin_page_template_url(assigns(:page_template))
  end

  def test_destroy
    page_template = PageTemplate.first
    delete :destroy, :id => page_template
    assert_redirected_to admin_page_templates_url
    assert !PageTemplate.exists?(page_template.id)
  end
end
