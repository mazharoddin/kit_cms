class RepoController < KitController

  def index
    @blocks = Block.sys(_sid).where(:repo=>1).all
  end

end
