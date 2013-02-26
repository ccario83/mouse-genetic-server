class GroupsController < ApplicationController
  def new
    @group = Group.new
    @users = User.all
  end
end
