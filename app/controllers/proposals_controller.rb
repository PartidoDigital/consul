class ProposalsController < ApplicationController
  include FeatureFlags
  include CommentableActions
  include FlagActions

  before_action :parse_tag_filter, only: :index
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary]
  before_action :destroy_map_location_association, only: :update
  before_action :can_create_proposal, only: [:new, :create]

  feature_flag :proposals

  feature_flag :proposals

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Proposal.proposals_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  before_action :find_proposal, :only => :show
  load_and_authorize_resource
  before_action :can_edit_proposal, only: [:edit, :update]

  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def show
    super
    @notifications = @proposal.notifications
    @related_contents = Kaminari.paginate_array(@proposal.relationed_contents).page(params[:page]).per(5)

    redirect_to proposal_path(@proposal), status: :moved_permanently if request.path != proposal_path(@proposal)
  end

  def create
    @proposal = Proposal.new(proposal_params.merge(author: current_user))

    if @proposal.save
      redirect_to share_proposal_path(@proposal), notice: I18n.t('flash.actions.create.proposal')
    else
      render :new
    end
  end

  def index_customization
    discard_archived
    load_retired
    load_successful_proposals
    load_featured unless @proposal_successful_exists
  end

  def vote
    @proposal.register_vote(current_user, 'yes')
    set_proposal_votes(@proposal)
  end

  def retire
    if valid_retired_params? && @proposal.update(retired_params.merge(retired_at: Time.current))
      redirect_to proposal_path(@proposal), notice: t('proposals.notice.retired')
    else
      render action: :retire_form
    end
  end

  def retire_form
  end

  def share
    if Setting['proposal_improvement_path'].present?
      @proposal_improvement_path = Setting['proposal_improvement_path']
    end
  end

  def vote_featured
    @proposal.register_vote(current_user, 'yes')
    set_featured_proposal_votes(@proposal)
  end

  def summary
    @proposals = Proposal.for_summary
    @tag_cloud = tag_cloud
  end

  private

    def proposal_params
      params.require(:proposal).permit(:title, :question, :summary, :description, :external_url, :video_url,
                                       :responsible_name, :tag_list, :terms_of_service, :geozone_id, :skip_map,
                                       image_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                       documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                       map_location_attributes: [:latitude, :longitude, :zoom])
    end

    def retired_params
      params.require(:proposal).permit(:retired_reason, :retired_explanation)
    end

    def valid_retired_params?
      @proposal.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:proposal][:retired_reason].blank?
      @proposal.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:proposal][:retired_explanation].blank?
      @proposal.errors.empty?
    end

    def resource_model
      Proposal
    end

    def set_featured_proposal_votes(proposals)
      @featured_proposals_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    def discard_archived
      @resources = @resources.not_archived unless @current_order == "archival_date"
    end

    def load_retired
      if params[:retired].present?
        @resources = @resources.retired
        @resources = @resources.where(retired_reason: params[:retired]) if Proposal::RETIRE_OPTIONS.include?(params[:retired])
      else
        @resources = @resources.not_retired
      end
    end

    def load_featured
      return unless !@advanced_search_terms && @search_terms.blank? && @tag_filter.blank? && params[:retired].blank? && @current_order != "recommendations"
      @featured_proposals = Proposal.not_archived.not_not_success.sort_by_confidence_score.limit(3)
      if @featured_proposals.present?
        set_featured_proposal_votes(@featured_proposals)
        @resources = @resources.where('proposals.id NOT IN (?)', @featured_proposals.map(&:id))
      end
    end

    def load_successful_proposals
      @proposal_successful_exists = Proposal.successful.exists?
    end

    def destroy_map_location_association
      map_location = params[:proposal][:map_location_attributes]
      if map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?
        MapLocation.destroy(map_location[:id])
      end
    end

    def can_create_proposal
      unless Proposal.can_create?
        redirect_to proposals_path, alert: "El periodo de creación de propuestas ha finalizado."
      end
    end

    def can_edit_proposal
      unless @proposal.open?
        redirect_to proposal_path(@proposal), alert: "Solo se pueden editar ideas que aún no han pasado por el estudio de viabilidad."
      end
    end

    def find_proposal
      @proposal = Proposal.find_by_id(params[:id])
      unless @proposal
        proposal = Proposal.unscoped.find_by_id(params[:id])
        if proposal && !proposal.hidden_at.blank?
          redirect_to proposals_path, alert: 'La idea que intenta acceder fue eliminada por un administrador.'
        end
      end
    end
end
