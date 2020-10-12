# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    can :read, [Publication, Taxon, Orthogroup, Lifestyle, Tree]

    if user.present?
      can :crud, ServerJob, user_id: user.id
      can :crud, PpgJob, user_id: user.id
      can :crud, BlastJob, user_id: user.id
      can :crud, Submission, user_id: user.id

      if user.admin?
        can :manage, :all
      elsif user.group_member?
        can :manage, :Submission, status: 'pending'
        can :manage, [Publication, Taxon, Orthogroup, Lifestyle, Tree]
      elsif user.editor?
        # TODO
      elsif user.user?
        # TODO
      end
    end

    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
