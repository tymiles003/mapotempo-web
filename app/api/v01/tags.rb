class V01::Tags < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      p = ActionController::Parameters.new(params)
      p = p[:tag] if p.key?(:tag)
      p.permit(:label)
    end
  end

  resource :tags do
    desc 'Fetch customer\'s tags.', {
      nickname: 'getTags'
    }
    get do
      present current_customer.tags.load, with: V01::Entities::Tag
    end

    desc 'Fetch tag.', {
      nickname: 'getTag'
    }
    get ':id' do
      present current_customer.tags.find(params[:id]), with: V01::Entities::Tag
    end

    desc 'Create tag.', {
      nickname: 'createTag',
      params: V01::Entities::Tag.documentation.except(:id).merge({
        label: { required: true }
      })
    }
    post  do
      tag = current_customer.tags.build(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc 'Update tag.', {
      nickname: 'updateTag',
      params: V01::Entities::Tag.documentation.except(:id)
    }
    put ':id' do
      tag = current_customer.tags.find(params[:id])
      tag.update(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc 'Delete tag.', {
      nickname: 'deleteTag'
    }
    delete ':id' do
      current_customer.tags.find(params[:id]).destroy
    end
  end
end
