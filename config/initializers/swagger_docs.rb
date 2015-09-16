Swagger::Docs::Config.register_apis({
  '0.1' => {
    # the extension used for the API
    :api_extension_type => :html,
    # the output location where your .json files are written to
    api_file_path: 'public',
    api_file_name: 'api-web/0.1/swagger_doc.json',
    # the URL base path to your API
    base_path: Mapotempo::Application.config.swagger_docs_base_path,
    # if you want to delete all .json files at each generation
    clean_directory: false,
    # add custom attributes to api-docs
    attributes: {
      info: {
        'title' => 'API Web',
        #'description' => '',
        #'termsOfServiceUrl' => '',
        #'contact' => '',
        #'license' => '',
        #'licenseUrl' => ''
      }
    }
  }
})


module Swagger::Docs
  class ApiDeclarationFile
    alias_method :old_generate_resource, :generate_resource

    def generate_resource
      resource = old_generate_resource
      resource['apis'].each{ |api|
        api['path'] = '/' +api['path']
      }
      resource
    end

    def path
      @metadata.path.gsub('api_web', 'api-web').gsub('v01', '0.1')
    end

    def resource_file_path
      debased_path.to_s
    end
  end

  class Config
    def self.transform_path(path, api_version)
     '/' +  path.gsub('api_web', 'api-web').gsub('v01', '0.1')
    end
  end
end
