require 'test_helper'

class Admin::PageTemplateTermsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Admin::PageTemplateTerm.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Admin::PageTemplateTerm.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Admin::PageTemplateTerm.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to admin_page_template_term_url(assigns(:page_template_term))
  end

  def test_edit
    get :edit, :id => Admin::PageTemplateTerm.first
    assert_template 'edit'
  end

  def test_update_invalid
    Admin::PageTemplateTerm.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Admin::PageTemplateTerm.first
    assert_template 'edit'
  end

  def test_update_valid
    Admin::PageTemplateTerm.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Admin::PageTemplateTerm.first
    assert_redirected_to admin_page_template_term_url(assigns(:page_template_term))
  end

  def test_destroy
    page_template_term = Admin::PageTemplateTerm.first
    delete :destroy, :id => page_template_term
    assert_redirected_to admin_page_template_terms_url
    assert !Admin::PageTemplateTerm.exists?(page_template_term.id)
  end
end
