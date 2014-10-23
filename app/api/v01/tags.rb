class V01::Tags < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      p = ActionController::Parameters.new(params)
      p = p[:tag] if p.has_key?(:tag)
      p.permit(:label)
    end
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
