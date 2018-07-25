class Admin::GeoNodesController < Admin::ApplicationController
  before_action :check_license, except: [:index, :destroy]
  before_action :load_node, only: [:edit, :update, :destroy, :repair, :toggle, :status]

  helper EE::GeoHelper

  def index
    @nodes = GeoNode.all.order(:id)
    @node = GeoNode.new

    unless Gitlab::Geo.license_allows?
      flash_now(:alert, 'You need a different license to enable Geo replication')
    end
  end

  def projects
    finder = Geo::ProjectRegistryStatusFinder.new

    case params[:sync_status]
    when 'never'
      @projects = finder.never_synced_projects.page(params[:page])
    when 'failed'
      @registries = finder.failed_projects.page(params[:page])
    when 'pending'
      @registries = finder.pending_projects.page(params[:page])
    else
      @registries = finder.synced_projects.page(params[:page])
    end
  end

  def recheck
    @registry = Geo::ProjectRegistry.find_by_id(params[:id])
    @registry.flag_repository_for_recheck
    flash[:notice] = "#{@registry.project.full_name} is scheduled for recheck"

    redirect_to projects_admin_geo_nodes_path
  end

  def resync
    @registry = Geo::ProjectRegistry.find_by_id(params[:id])
    @registry.flag_repository_for_resync
    flash[:notice] = "#{@registry.project.full_name} is scheduled for resync"

    redirect_to projects_admin_geo_nodes_path
  end

  def force_redownload
    @registry = Geo::ProjectRegistry.find_by_id(params[:id])
    @registry.flag_repository_for_redownload
    flash[:notice] = "#{@registry.project.full_name} is scheduled for forced redownload"

    redirect_to projects_admin_geo_nodes_path
  end

  def create
    @node = Geo::NodeCreateService.new(geo_node_params).execute

    if @node.persisted?
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully created.'
    else
      @nodes = GeoNode.all

      render :new
    end
  end

  def new
    @node = GeoNode.new
  end

  def update
    if Geo::NodeUpdateService.new(@node, geo_node_params).execute
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully updated.'
    else
      render :edit
    end
  end

  private

  def geo_node_params
    params.require(:geo_node).permit(
      :url,
      :primary,
      :selective_sync_type,
      :selective_sync_shards,
      :namespace_ids,
      :repos_max_capacity,
      :files_max_capacity,
      :verification_max_capacity
    )
  end

  def check_license
    unless Gitlab::Geo.license_allows?
      flash[:alert] = 'You need a different license to enable Geo replication'
      redirect_to admin_license_path
    end
  end

  def load_node
    @node = GeoNode.find(params[:id])
  end

  def flash_now(type, message)
    flash.now[type] = flash.now[type].blank? ? message : "#{flash.now[type]}<BR>#{message}".html_safe
  end
end
