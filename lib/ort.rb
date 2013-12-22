require 'tempfile'

module Ort

  @exec = Mapotempo::Application.config.optimizer_exec
  @tmp_dir = Mapotempo::Application.config.optimizer_tmp_dir

  def self.optimize(capacity, matrix, time_window)
    input = Tempfile.new('optimize-route-input', tmpdir=@tmp_dir)
    output = Tempfile.new('optimize-route-output', tmpdir=@tmp_dir)

    begin
      output.close

      input.write(matrix.size)
      input.write("\n")
      input.write(matrix.collect{ |a| a.collect{ |b| b.join(" ") }.join(" ") }.join("\n"))
      input.write("\n")
      input.write(time_window.collect{ |a| a.collect{ |b| b ? b : -1 }.join(" ") }.join("\n"))
      input.write("\n")

      input.close

      `cat #{input.path} > /tmp/in` # FIXME tmp
      capacity_arg = capacity ? "-max #{capacity}" : ""
      cmd = "#{@exec} -time_limit_in_ms 2000 #{capacity_arg} -instance_file '#{input.path}' > '#{output.path}'"
      Rails.logger.info(cmd)
      system(cmd)
      Rails.logger.info($?.exitstatus)
      `cat #{output.path} > /tmp/out` # FIXME tmp
      if $?.exitstatus == 0
        result = File.read(output.path)
        result = result.split("\n")[-1]
        Rails.logger.info result.inspect
        result.split(' ').collect{ |i| Integer(i) }
      end
    ensure
      input.unlink
      output.unlink
    end
  end
end
