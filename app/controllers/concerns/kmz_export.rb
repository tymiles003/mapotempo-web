module KmzExport
  extend ActiveSupport::Concern

  def kmz_string_io options={}
    Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry(filename + '.kml')
      if options[:route]
        zio.write render_to_string(
          template: "routes/show",
          formats: :kml,
          locals: options.slice(:route)
        )
      elsif options[:planning]
        zio.write render_to_string(
          template: "plannings/show",
          formats: :kml,
          locals: options.slice(:planning)
        )
      end
      store_img_path = 'marker-home.png'
      zio.put_next_entry(store_img_path)
      zio.print IO.read('public/' + store_img_path)
      if options[:with_home_markers]
        (COLORS_TABLE + ['#000000']).each { |color|
          img_path = 'marker-home-' + color[1..-1] + '.png'
          zio.put_next_entry(img_path)
          zio.print IO.read('public/' + img_path)
        }
      end
      (COLORS_TABLE + ['#707070']).each { |color|
        img_path = 'point-' + color[1..-1] + '.png'
        zio.put_next_entry(img_path)
        zio.print IO.read('public/' + img_path)
      }
    end
  end

end
