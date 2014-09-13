class V01::Tags < Grape::API
  version '0.1', using: :path

  helpers do
    def current_customer
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && @current_user.customer
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_customer
      error!('402 Payment Required', 402) if @current_customer.end_subscription && @current_customer.end_subscription > Time.now
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      p = ActionController::Parameters.new(params)
      p = p[:tag] if p.has_key?(:tag)
      p.permit(:label)
    end
  end

  before do
    authenticate!
    ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      ActiveRecord::Base.connection.commit_transaction unless @error
    rescue Exception
      ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    @error = e
    Rails::logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    error_response({message: e.message})
  end

  resource :tags do
    desc "Return customer's tags."
    get do
      present current_customer.tags.load, with: V01::Entities::Tag
    end

    desc "Return a tag."
    get ':id' do
      present current_customer.tags.find(params[:id]), with: V01::Entities::Tag
    end

    desc "Create a tag.", {
      params: V01::Entities::Tag.documentation.except(:id)
    }
    post  do
      tag = current_customer.tags.build(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc "Update a tag.", {
      params: V01::Entities::Tag.documentation.except(:id)
    }
    put ':id' do
      tag = current_customer.tags.find(params[:id])
      tag.update(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc "Destroy a tag."
    delete ':id' do
      current_customer.tags.find(params[:id]).destroy
    end
  end
end
