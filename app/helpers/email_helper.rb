module EmailHelper
  def email_image_tag(image, **options)
    image_name = image
    if image.start_with?('/uploads')
      image_name = image.split('/').last
      attachments[image_name] = File.read(Rails.root.join("public/#{image}")) if attachments[image_name].nil?
    else
      attachments[image_name] = File.read(Rails.root.join("app/assets/images/#{image}")) if attachments[image_name].nil?
    end

    image_tag attachments[image_name].url, **options
  end
end
